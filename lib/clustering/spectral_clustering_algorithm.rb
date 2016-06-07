require 'matrix'
require 'matrix/eigenvalue_decomposition'


module ClusteringModule
  class SpectralClusteringAlgorithm
    def initialize(similarity_matrix)
      @similarity_matrix = similarity_matrix
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

      # Use uniq to prevent duplicate vectors
      clusters = y.uniq{|v| v.map{|j| j.round(0)}}.sample(kappa).map{|v| [y.index(v)]}

      centroids = clusters.map{ |cl| get_centroid(cl, y, y[0] - y[0]) }

      loop do
        # puts "clusters: #{clusters}"
        #  stats(clusters)

        # puts "centroids: #{centroids}"
        old_centroids = Array.new(centroids)
        clusters = []
        y.each_with_index do |y_i, i|
          closest = find_closest(y_i, centroids)
          clusters[closest] ||= []
          clusters[closest].push i
        end

        # puts JSON.pretty_generate clusters
        centroids = clusters.map.with_index { |cl, i| get_centroid(cl, y, old_centroids[i]) }

        break if centroids <=> old_centroids
      end

      clusters
    end

    private

    def get_centroid(cluster, y, old_centroid)
      (cluster.sum { |i| y[i] } + old_centroid) / (cluster.length + 1)
    end

    def find_closest(vector, centroids)
      centroids.index(centroids.min_by {|c| (c - vector).magnitude })
    end

  end

end