# Author::    Sergio Fierens
# License::   MPL 1.1
# Project::   ai4r
# Url::       http://ai4r.org/
#
# You can redistribute it and/or modify it under the terms of 
# the Mozilla Public License version 1.1  as published by the 
# Mozilla Foundation at http://www.mozilla.org/MPL/MPL-1.1.txt

require 'set'

module Ai4r
  
  module GeneticAlgorithm

    class GeneticSearchWithOptions < GeneticSearch

      def initialize(initial_population_size, generations, options = {})
        @population_size = initial_population_size
        @max_generation = generations
        @generation = 0
        @options = options
        @chromosomeClass = options[:class]
      end

      def generate_initial_population
       @population = []
       puts "INIT: TARGETS: #{@options[:targets]}"
       puts "INIT: REAL: #{@options[:real_prosumption]}" unless @options[:real_prosumption].nil?

       @options[:stats] ||= {}
       @options[:stats][:start_run] = Time.now
       @population_size.times do
         population << @chromosomeClass.seed(@options)
       end
      end


      # We combine each pair of selected chromosome using the method
      # Chromosome.reproduce
      #
      # The reproduction will also call the Chromosome.mutate method with
      # each member of the population. You should implement Chromosome.mutate
      # to only change (mutate) randomly. E.g. You could effectivly change the
      # chromosome only if
      #     rand < ((1 - chromosome.normalized_fitness) * 0.4)
      def reproduction(selected_to_breed)
        offsprings = []
        0.upto(selected_to_breed.length/2-1) do |i|
          offsprings << @chromosomeClass.reproduce(selected_to_breed[2*i], selected_to_breed[2*i+1])
        end
        @population.each do |individual|
          @chromosomeClass.mutate(individual)
        end
        return offsprings
      end


      #     1. Choose initial population
      #     2. Evaluate the fitness of each individual in the population
      #     3. Repeat
      #           1. Select best-ranking individuals to reproduce
      #           2. Breed new generation through crossover and mutation (genetic operations) and give birth to offspring
      #           3. Evaluate the individual fitnesses of the offspring
      #           4. Replace worst ranked part of population with offspring
      #     4. Until termination
      #     5. Return the best chromosome
      def run
        generate_initial_population                    #Generate initial population

        @max_generation.times do |i|

          message = "Generation: #{i}, best fitness: #{@population[0].fitness}"
          @options[:stats][:gen] ||= []
          @options[:stats][:gen][i] = {
              fitness: @population[0].fitness,
              time: Time.now - @options[:stats][:start_run]
          }
          puts message
          unless @options[:rb_channel].nil?
            @options[:rb_channel].publish({data: message, event: 'output'}.to_json)
          end

          selected_to_breed = selection                #Evaluates current population
          offsprings = reproduction selected_to_breed  #Generate the population for this new generation
          replace_worst_ranked offsprings
        end
        return best_chromosome
      end
    end
    # A Chromosome is a representation of an individual solution for a specific 
    # problem. You will have to redifine the Chromosome representation for each
    # particular problem, along with its fitness, mutate, reproduce, and seed 
    # methods.
    class StaticChromosome < Chromosome

      attr_accessor :data
      attr_accessor :normalized_fitness
      attr_accessor :options

      def initialize(data, options)
        # puts "data, options: #{data}, #{options[:errors].length}"


        if options.nil?
          puts Thread.current.backtrace.join("\n")
          Thread.exit
        end

        @data = data
        @options = options
        @errors = options[:errors]
        @prosumers = options[:prosumers]
      end

      # The fitness method quantifies the optimality of a solution 
      # (that is, a chromosome) in a genetic algorithm so that that particular 
      # chromosome may be ranked against all the other chromosomes. 
      # 
      # Optimal chromosomes, or at least chromosomes which are more optimal, 
      # are allowed to breed and mix their datasets by any of several techniques, 
      # producing a new generation that will (hopefully) be even better.
      def fitness
        return @fitness if @fitness

        cls = (options[:kappa]).times.map { |i| [] }
        @data.each_with_index { |g, i| cls[g].push i}

        p_b2 = cls.map { |c| penalty_before(c) }
        p_a2 = cls.map { |c| penalty_after(c) }

        impr2 = p_b2.zip(p_a2).sum do |b,a|
          b > 0 ? ((b - a)/b) : 0
        end

        @fitness = impr2
      end

      def penalty_before(cluster)
        @cache_penalty_before ||= {}
        @cache_penalty_before[cluster] ||= cluster.sum do |p|
          @options[:penalties_before][p]
        end
      end

      def penalty_after(cluster)
        @cache_penalty_after||= {}
        @cache_penalty_after[cluster] ||= @options[:timestamps].sum do |t|
          v = cluster.sum do |p|
            @errors[[@prosumers[p].id ,t]] || 0
          end
          self.class.penalty(v, @options)
        end
      end

      # mutation method is used to maintain genetic diversity from one 
      # generation of a population of chromosomes to the next. It is analogous 
      # to biological mutation. 
      # 
      # The purpose of mutation in GAs is to allow the 
      # algorithm to avoid local minima by preventing the population of 
      # chromosomes from becoming too similar to each other, thus slowing or even 
      # stopping evolution.
      # 
      # Calling the mutate function will "probably" slightly change a chromosome
      # randomly. 
      #
      # This implementation of "mutation" will (probably) reverse the 
      # order of 2 consecutive randome nodes 
      # (e.g. from [ 0, 1, 2, 4] to [0, 2, 1, 4]) if:
      #     ((1 - chromosome.normalized_fitness) * 0.4)
      def self.mutate(chromosome)
        if chromosome.normalized_fitness && rand < ((1 - chromosome.normalized_fitness) * 0.3)
          data = chromosome.data
          index = rand(data.length-1)
          data[index], data[index+1] = data[index+1], data[index]
          chromosome.data = data
          @fitness = nil
        end
      end

      # Reproduction method is used to combine two chromosomes (solutions) into 
      # a single new chromosome. There are several ways to
      # combine two chromosomes: One-point crossover, Two-point crossover,
      # "Cut and splice", edge recombination, and more. 
      # 
      # The method is usually dependant of the problem domain.
      # In this case, we have implemented edge recombination, wich is the 
      # most used reproduction algorithm for the Travelling salesman problem.
      def self.reproduce(a, b)

        #Two point crossover
        current = rand(2)
        point1 = rand(a.data.length)
        point2 = rand(a.data.length)
#        puts "reproduce, #{point1}, #{point2}"
        spawn = a.data.zip(b.data).map.with_index do |g, i|
          current = 1 - current if (i == point1) ^ (i == point2)
       #    puts "#{g[0]},#{g[1]},#{i},#{current}, #{g[current]}"
          g[current]
        end


        # The following is uniform crossover
        # spawn = a.data.zip(b.data).map do |g1 ,g2|
        #   rand(2) > 0 ? g1 : g2
        # end

        return self.new(spawn, a.options)
      end

      # Initializes an individual solution (chromosome) for the initial 
      # population. Usually the chromosome is generated randomly, but you can 
      # use some problem domain knowledge, to generate a 
      # (probably) better initial solution.
      def self.seed(options)
        data_size = options[:prosumers].length
        kappa = options[:kappa]

        seed = []
        0.upto(data_size-1) do
          seed << rand(kappa)
        end

        options[:timestamps] = options[:errors].map{|(pid,t), v| t}.to_set
        options[:penalties_before] = options[:prosumers].map do |p|
          options[:timestamps].sum do |t|
            penalty(options[:errors][[p.id, t]] || 0, options)
          end
        end

        # puts "seed options: #{options[:errors].length}, timestamps: #{options[:timestamps]}, pb: #{options[:penalties_before]}"
        return self.new(seed, options)
      end

      def self.set_cost_matrix(costs)
        @@costs = costs
      end

      private
      def self.penalty(error, options)
        (error > 0 ? options[:penalty_violation] : options[:penalty_satisfaction]) * error.abs
      end
    end

    class StaticChromosomeWithSmartCrossover < StaticChromosome

      def self.reproduce(a, b)

        clusters = create_clusters(a,b)
        spawn = a.data.map { |p| a.options[:kappa]- 1 }
        0.upto(a.options[:kappa] - 2) do |cluster_index|
       #    puts "a: #{a.data}, b:#{b.data}, spawn: #{spawn}, CLUSTERS: #{clusters}"
          best = clusters.sort_by do |c|
            before = a.penalty_before(c)
            after = a.penalty_after(c)
            before > 0 ? (before - after) / before : 0
          end.last
          clusters -= [best]
          best.each do |p|
            spawn[p] = cluster_index
            clusters.each{|c| c.delete p}
          end
          clusters.reject!{|c| c.size == 0}
        end
       #  puts "#{spawn }"
        return self.new(spawn, a.options)
      end

      private


      def self.create_clusters(a, b)
        clusters = (2 * a.options[:kappa]).times.map { |i| [] }
        a.data.each_with_index { |g, i| clusters[g].push i}
        b.data.each_with_index { |g, i| clusters[g + a.options[:kappa]].push i}
        clusters
      end

    end

  end
end
