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
          if @options[:rb_channel].nil?
            puts message
          else
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

        clusters = []
        # puts "gen",genotypes.size
        @data.each_with_index do |v, i|
          clusters[@prosumers[i].id] = v
        end

        cl_errors = {}
        base_errors = {}
        @errors.each do |k,v|
          cl_errors[[clusters[k[0]], k[1]]] ||= 0
          cl_errors[[clusters[k[0]], k[1]]] += v
          base_errors[[clusters[k[0]], k[1]]] ||= 0
          base_errors[[clusters[k[0]], k[1]]] += penalty(v)
        end

        p_b = base_errors.inject({}) do |s, (k,v)|
          s[k[0]] ||= 0
          s[k[0]] += v
          s
        end

     #   puts "p_b: #{p_b}"

        p_a = cl_errors.inject({}) do |s, (k,v)|
          # puts "printing", s, k, v
          s[k[0]] ||= 0
          s[k[0]] += penalty(v)
          s
        end

     #   puts "p_a: #{p_a}"

        best_cluster = p_a.max_by do |k,v|
          if p_b[k] > 0
            (p_b[k] - v) / p_b[k]
          else
            0
          end
        end

        improvements = p_a.sum do |k,v|
          p_b[k] > 0 ?
              (p_b[k] - v) / p_b[k] :
              0
        end

        total_error = p_a.sum do |k,v|
          v
        end


     #   puts "best_cluster: #{best_cluster}"
     #   puts "result: #{(p_b[best_cluster[0]] - p_a[best_cluster[0]]) / p_b[best_cluster[0]]}"
     #   puts "result2: #{improvements}"

        # @fitness = (p_b[best_cluster[0]] - p_a[best_cluster[0]]) / p_a[best_cluster[0]]
        @fitness = improvements
        # @fitness = -total_error
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

        return StaticChromosome.new(spawn, a.options)
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
        puts "seed options: #{options[:errors].length}"
        return StaticChromosome.new(seed, options)
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
