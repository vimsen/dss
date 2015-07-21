# Author::    Sergio Fierens
# License::   MPL 1.1
# Project::   ai4r
# Url::       http://ai4r.org/
#
# You can redistribute it and/or modify it under the terms of 
# the Mozilla Public License version 1.1  as published by the 
# Mozilla Foundation at http://www.mozilla.org/MPL/MPL-1.1.txt
module Ai4r
  
  module GeneticAlgorithm

    # A Chromosome is a representation of an individual solution for a specific
    # problem. You will have to redifine the Chromosome representation for each
    # particular problem, along with its fitness, mutate, reproduce, and seed 
    # methods.
    class DynamicChromosome < Chromosome

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
        @targets_per_cluster = options[:targets]
        @real_consumption = options[:real_consumption]
        @prosumers = options[:prosumers]
        @initial_imballance = options[:initial_imballance]

    #    puts "TARGETS: #{@targets_per_cluster}"
    #    puts "REAL: #{@targets_per_cluster}"
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

        consumption_per_cluster = {}
        @data.each_with_index do |v, i|
          consumption_per_cluster[v] ||= 0
          # puts @prosumers[i].id, @real_consumption
          consumption_per_cluster[v] += (@real_consumption[@prosumers[i].id] || 0)
        end

        total_penalties_before = @initial_imballance.map do |imballance|
          penalty(imballance)
        end

        total_penalties_after = 0
        res = 0;

        consumption_per_cluster.each do |cluster, consumption |
          #  puts "DEBUG: #{cluster}, #{consumption}"
          p = penalty((consumption || 0) - (@targets_per_cluster[cluster] || 0))
          res += 100 * (total_penalties_before[cluster] - p) / total_penalties_before[cluster] if total_penalties_before[cluster] > 0
        end




        @fitness =  res

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

        return DynamicChromosome.new(spawn, a.options)
      end

      # Initializes an individual solution (chromosome) for the initial 
      # population. Usually the chromosome is generated randomly, but you can 
      # use some problem domain knowledge, to generate a 
      # (probably) better initial solution.
      def self.seed(options)

      #  puts "I am in the corrext seed function, options: #{options}"
        data_size = options[:prosumers].length
        kappa = options[:kappa]

        seed = []
        0.upto(data_size-1) do
          seed << rand(kappa)
        end
       #  puts "seed options: #{options[:errors].length}"
        return DynamicChromosome.new(seed, options)
      end

      def self.set_cost_matrix(costs)
        @@costs = costs
      end

      private
      def penalty(error)
        (error > 0 ? @options[:penalty_violation] : @options[:penalty_satisfaction]) * error.abs
      end
    end

  end

end
