require 'matrix'
require 'matrix/eigenvalue_decomposition'


module ClusteringModule
  class SpectralClustering

    def initialize(prosumers: Prosumer.all,
                   startDate: Time.now - 1.week,
                   endDate: Time.now)
      method(__method__).parameters.each do |type, k|
        next unless type == :key
        v = eval(k.to_s)
        instance_variable_set("@#{k}", v) unless v.nil?
        Rails.logger.debug("key: @#{k}")
        Rails.logger.debug("value: #{v}")
      end

      @forecasts = Hash[DataPoint.where(prosumer: @prosumers,
                                       interval: 2,
                                       f_timestamp: @startDate .. @endDate)
                           .map do |dp|
                         [[dp.prosumer_id, dp.f_timestamp.to_i], dp.f_consumption]
                       end]

      @real =  Hash[DataPoint.where(prosumer: @prosumers,
                                   interval: 2,
                                   timestamp: @startDate .. @endDate)
                       .map do |dp|
                     [[dp.prosumer_id, dp.timestamp.to_i], dp.consumption]
                   end]

      @timestamps = Hash[@prosumers.map{|p| [p.id,[]] }]

      @errors = Hash[@real.map do |(pid,timestamp),v|
                      # @timestamps[pid] ||= []
                      @timestamps[pid].push timestamp
                      [ [pid, timestamp], v - (@forecasts[[pid, timestamp]] || 0)]
                     end]

      @similarity_matrix = Matrix.build(@prosumers.length, @prosumers.length)  do |row, col|
        cross_correlation(@prosumers[row].id, @prosumers[col].id) + 1 # We need similarities to always be positive
      end

    end

    def run(kappa = 5)
                                     # v---- This is a "splat" operator
      degree_matrix = Matrix.diagonal *@similarity_matrix.row_vectors.map{|v| v.sum}

      unnormalized_laplacian = degree_matrix - @similarity_matrix

      decomposition = Matrix::EigenvalueDecomposition.new(unnormalized_laplacian)

      u = Matrix.columns(decomposition.eigenvectors.take(kappa))

      y = u.row_vectors

      # puts decomposition.eigenvalues.take(kappa).join(",\n")
      # puts decomposition.eigenvectors.take(kappa).join(",\n")
      # puts u

      # puts y.join(",\n")

      clusters = y.sample(kappa).map{|i| [y.index(i)]}

      centroids = clusters.map{ |cl| get_centroid(cl, y) }

      loop do
      #   puts "clusters: #{clusters}"
      #  stats(clusters)


        old_centroids = Array.new(centroids)
        clusters = []
        y.each_with_index do |y_i, i|
          closest = find_closest(y_i, centroids)
          clusters[closest] ||= []
          clusters[closest].push i
        end

        centroids = clusters.map{ |cl| get_centroid(cl, y) }

        break if centroids <=> old_centroids
      end

      clusters.map.with_index do |cl, i|
        TempCluster.new(name: "Spectral #{i}",
                        description: "Spectral error clustering #{i}",
                        prosumers: cl.map { |p| @prosumers[p]})
      end
    end

    def cross_correlation(pid1, pid2)
      common_timestamps = @timestamps[pid1] & @timestamps[pid2]

      s12 = common_timestamps.sum{|ts| @errors[[pid1, ts]] * @errors[[pid2, ts]]}
      s11 = common_timestamps.sum{|ts| @errors[[pid1, ts]] ** 2 }
      s22 = common_timestamps.sum{|ts| @errors[[pid2, ts]] ** 2 }

      return 0 if (s11 == 0 || s22 == 0)
      s12 / ( s11 ** 0.5 * s22 ** 0.5)
    end

    def get_centroid(cluster, y)
      cluster.sum { |i| y[i] } / cluster.length
    end


    def find_closest(vector, centroids)
      centroids.index(centroids.min_by {|c| (c - vector).magnitude })
    end

    def stats(clusters)
      sum_same = sum_different = 0.0;
      count_same = count_different = 0
      @prosumers.combination(2) do |pi,pj|
        i = @prosumers.index(pi)
        j = @prosumers.index(pj)

        if same_cluster(clusters, i,j)
          sum_same += @similarity_matrix[i,j] - 1
          count_same += 1
        else
          sum_different += @similarity_matrix[i,j] - 1
          count_different += 1
        end
      end
      {
          ingroup: sum_same / count_same,
          outgroup: sum_different / count_different
      }
    end

    def same_cluster(clusters, i,j)
      clusters.find{|k| k.include? i} == clusters.find{|k| k.include? j}
    end

  end
end