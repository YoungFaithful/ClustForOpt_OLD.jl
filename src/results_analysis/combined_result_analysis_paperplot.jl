using ClustForOpt
using JLD2 # Much faster than JLD (50s vs 20min)
using FileIO

using PyPlot
using DataFrames
plt = PyPlot

regions = ["GER","CA"]
problem_types = ["battery","gas_turbine"]
plot_types = ["trad_cen","trad_med","shape"]

 # settings for example figures
example_figs_region="GER"
example_figs_n_clust = 3
e_f_centers = Dict{String,Array{Float64,2}}()
e_f_weights = Dict{String,Array{Float64,1}}()
 
 # initialize variables before the loop
clust_methods = Dict{String,Array{Dict,1}}()
n_clust_ar =[] 

for region_ in regions
  for problem_type in problem_types

    region = region_

     
    # read in original data
    data_orig_daily = load_pricedata(region)
    seq = data_orig_daily[:,1:365]  # do not load as sequence

    # optimization on original data
    revenue_orig_daily = sum(run_opt(problem_type,data_orig_daily,1,region,false));

     # set up some common variables
    revenue_dict = Dict{String,Array}()
    revenue_best = Dict{String, Array}()
    cost_dict = Dict{String,Array}()
    cost_best = Dict{String,Array}()

    ##### k-means #############

     # read parameters
    param=DataFrame()
    try
      param = readtable(joinpath("outfiles",string("parameters_kmeans_",region_,".txt")))
    catch
      error("No input file parameters.txt exists in folder outfiles.")
    end

    n_clust_min=param[:n_clust_min][1]
    n_clust_max=param[:n_clust_max][1]
    n_init=param[:n_init][1]
    iterations=param[:iterations][1]
    region=param[:region][1]

    n_clust_ar = collect(n_clust_min:n_clust_max)

     # load saved JLD data
    saved_data_dict= load(string(joinpath("outfiles","aggregated_results_kmeans_"),region_,".jld2"))
    #unpack saved JLD data
    # string _ is added because calling weights later gives weird error where weights from StatsBase is called. 
     for (k,v) in saved_data_dict
       @eval $(Symbol(string(k,"_"))) = $v
     end

     #set revenue to the chosen problem type
    revenue_dict["kmeans"] =revenue_[problem_type] 
    cost_dict["kmeans"] = cost_

     # Find best cost index - save
    ind_mincost = findmin(cost_,2)[2]  # along dimension 2
    ind_mincost = reshape(ind_mincost,size(ind_mincost,1))
    revenue_best["kmeans"] = zeros(size(revenue_dict["kmeans"],1))
    cost_best["kmeans"] = zeros(size(cost_dict["kmeans"],1))
    for i=1:size(revenue_dict["kmeans"],1)
        revenue_best["kmeans"][i]=revenue_dict["kmeans"][ind_mincost[i]] 
        cost_best["kmeans"][i]=cost_dict["kmeans"][ind_mincost[i]] 
    end

    if region == example_figs_region 
      e_f_centers["kmeans"]=centers_[example_figs_n_clust,ind_mincost[example_figs_n_clust]]
      e_f_weights["kmeans"]=weights_[example_figs_n_clust,ind_mincost[example_figs_n_clust]]
    end

    #### k-means with medoid as representation ###

     # read parameters
    param=DataFrame()
    try
      param = readtable(joinpath("outfiles",string("parameters_kmeans_medoidrep",region_,".txt")))
    catch
      error("No input file parameters.txt exists in folder outfiles.")
    end

    n_clust_min=param[:n_clust_min][1]
    n_clust_max=param[:n_clust_max][1]
    n_init=param[:n_init][1]
    iterations=param[:iterations][1]
    region=param[:region][1]

    n_clust_ar = collect(n_clust_min:n_clust_max)

     # load saved JLD data
    saved_data_dict= load(string(joinpath("outfiles","aggregated_results_kmeans_medoidrep"),region_,".jld2"))
    #unpack saved JLD data
    # string _ is added because calling weights later gives weird error where weights from StatsBase is called. 
     for (k,v) in saved_data_dict
       @eval $(Symbol(string(k,"_"))) = $v
     end

     #set revenue to the chosen problem type
    revenue_dict["kmeans_medoidrep"] =revenue_[problem_type] 
    cost_dict["kmeans_medoidrep"] = cost_

     # Find best cost index - save
    ind_mincost = findmin(cost_,2)[2]  # along dimension 2
    ind_mincost = reshape(ind_mincost,size(ind_mincost,1))
    revenue_best["kmeans_medoidrep"] = zeros(size(revenue_dict["kmeans_medoidrep"],1))
    cost_best["kmeans_medoidrep"] = zeros(size(cost_dict["kmeans_medoidrep"],1))
    for i=1:size(revenue_dict["kmeans_medoidrep"],1)
        revenue_best["kmeans_medoidrep"][i]=revenue_dict["kmeans_medoidrep"][ind_mincost[i]] 
        cost_best["kmeans_medoidrep"][i]=cost_dict["kmeans_medoidrep"][ind_mincost[i]] 
    end


     ##### k-medoids #######


     # read parameters
    param=DataFrame()
    try
      param = readtable(joinpath("outfiles",string("parameters_kmedoids_",region_,".txt")))
    catch
      error("No input file parameters.txt exists in folder outfiles.")
    end

    n_clust_min=param[:n_clust_min][1]
    n_clust_max=param[:n_clust_max][1]
    n_init=param[:n_init][1]
    iterations=param[:iterations][1]
    region=param[:region][1]

    n_clust_ar = collect(n_clust_min:n_clust_max)

    dist_type = "SqEuclidean"   # "SqEuclidean"   "Cityblock"

     # load saved JLD data - kmeans algorithm of kmedoids
    saved_data_dict= load(string(joinpath("outfiles","aggregated_results_kmedoids_"),dist_type,"_",region_,".jld2"))
     #unpack saved JLD data
     for (k,v) in saved_data_dict
       @eval $(Symbol(string(k,"_"))) = $v
     end

     #set revenue to the chosen problem type
    revenue_dict["kmedoids"]=revenue_[problem_type] 
    cost_dict["kmedoids"] = cost_

     # Find best cost index - save
    ind_mincost = findmin(cost_,2)[2]  # along dimension 2
    ind_mincost = reshape(ind_mincost,size(ind_mincost,1))
    revenue_best["kmedoids"] = zeros(size(revenue_dict["kmedoids"],1))
    for i=1:size(revenue_dict["kmedoids"],1)
        revenue_best["kmedoids"][i]=revenue_dict["kmedoids"][ind_mincost[i]] 
    end

 # for ecample plots
    if region == example_figs_region 
      e_f_centers["kmedoids"]=centers_[example_figs_n_clust,ind_mincost[example_figs_n_clust]]
      e_f_weights["kmedoids"]=weights_[example_figs_n_clust,ind_mincost[example_figs_n_clust]]
    end
    
    # load saved JLD data - exact algorithm of kmedoids
    saved_data_dict= load(string(joinpath("outfiles","aggregated_results_kmedoids_exact_"),dist_type,"_",region_,".jld2"))
     #unpack saved JLD data
     for (k,v) in saved_data_dict
       @eval $(Symbol(string(k,"_"))) = $v
     end

     #set revenue to the chosen problem type
    revenue_dict["kmedoids_exact"]=revenue_[problem_type] 
    cost_dict["kmedoids_exact"] = cost_

     # Find best cost index -exact - not necessary, but legacy code
    ind_mincost = findmin(cost_,2)[2]  # along dimension 2
    ind_mincost = reshape(ind_mincost,size(ind_mincost,1))
    revenue_best["kmedoids_exact"] = zeros(size(revenue_dict["kmedoids_exact"],1))
    for i=1:size(revenue_dict["kmedoids_exact"],1)
        revenue_best["kmedoids_exact"][i]=revenue_dict["kmedoids_exact"][ind_mincost[i]] 
    end


     ##### hierarchical clustering #######

     # read parameters
    param=DataFrame()
    try
      param = readtable(joinpath("outfiles",string("parameters_hier_",region_,".txt")))
    catch
      error("No input file parameters.txt exists in folder outfiles.")
    end

    n_clust_min=param[:n_clust_min][1]
    n_clust_max=param[:n_clust_max][1]
    n_init=param[:n_init][1]
    iterations=param[:iterations][1]
    region=param[:region][1]

    n_clust_ar = collect(n_clust_min:n_clust_max)

     # load saved JLD data
    saved_data_dict= load(string(joinpath("outfiles","aggregated_results_hier_centroid_"),region_,".jld2"))
     #unpack saved JLD data
     for (k,v) in saved_data_dict
       @eval $(Symbol(string(k,"_centroid"))) = $v
     end

     #set revenue to the chosen problem type
    revenue_dict["hier_centroid"]=revenue_centroid[problem_type] 
    cost_dict["hier_centroid"] = cost_centroid

     # Find best cost index - save
    ind_mincost = findmin(cost_centroid,2)[2]  # along dimension 2
    ind_mincost = reshape(ind_mincost,size(ind_mincost,1))
    revenue_best["hier_centroid"] = zeros(size(revenue_dict["hier_centroid"],1))
    for i=1:size(revenue_dict["hier_centroid"],1)
        revenue_best["hier_centroid"][i]=revenue_dict["hier_centroid"][ind_mincost[i]] 
    end
     
     # load saved JLD data
    saved_data_dict= load(string(joinpath("outfiles","aggregated_results_hier_medoid_"),region_,".jld2"))
     #unpack saved JLD data
     for (k,v) in saved_data_dict
       @eval $(Symbol(string(k,"_medoid"))) = $v
     end

     #set revenue to the chosen problem type
    revenue_dict["hier_medoid"]=revenue_medoid[problem_type] 
    cost_dict["hier_medoid"] = cost_medoid

     # Find best cost index - save
    ind_mincost = findmin(cost_medoid,2)[2]  # along dimension 2
    ind_mincost = reshape(ind_mincost,size(ind_mincost,1))
    revenue_best["hier_medoid"] = zeros(size(revenue_dict["hier_medoid"],1))
    for i=1:size(revenue_dict["hier_medoid"],1)
        revenue_best["hier_medoid"][i]=revenue_dict["hier_medoid"][ind_mincost[i]] 
    end

     ##### Dynamic Time Warping #####
     #window =1, window =2

     # read parameters
    param=DataFrame()
    try
      param = readtable(joinpath("outfiles",string("parameters_dtw_",region_,".txt")))
    catch
      error("No input file parameters.txt exists in folder outfiles.")
    end

    n_clust_min=param[:n_clust_min][1]
    n_clust_max=param[:n_clust_max][1]
    n_init=param[:n_init][1]
    n_dbaclust=param[:n_dbaclust][1]
    rad_sc_min=param[:rad_sc_min][1]
    rad_sc_max=param[:rad_sc_max][1]
    iterations=param[:iterations][1]
    inner_iterations=param[:inner_iterations][1]
    region=param[:region][1]

    n_clust_ar = collect(n_clust_min:n_clust_max)
    rad_sc_ar = collect(rad_sc_min:rad_sc_max)


     # load saved JLD data
    saved_data_dict= load(string(joinpath("outfiles","aggregated_results_dtw_"),region_,".jld2"))
     #unpack saved JLD data
     for (k,v) in saved_data_dict
       @eval $(Symbol(string(k,"_"))) = $v
     end

     #set revenue to the chosen problem type
    revenue_dict["dtw"]=revenue_[problem_type] 
    cost_dict["dtw"] = cost_

     # Find best cost index - save
    ind_mincost = findmin(cost_,3)[2]  # along dimension 3
    ind_mincost = reshape(ind_mincost,size(ind_mincost,1),size(ind_mincost,2))
    revenue_best["dtw"] = zeros(size(revenue_dict["dtw"],1),size(revenue_dict["dtw"],2))
    cost_best["dtw"] = zeros(size(cost_dict["dtw"],1),size(cost_dict["dtw"],2))
    for i=1:size(revenue_dict["dtw"],1)
      for j=1:size(revenue_dict["dtw"],2)
        revenue_best["dtw"][i,j]=revenue_dict["dtw"][ind_mincost[i,j]] 
        cost_best["dtw"][i,j]=cost_dict["dtw"][ind_mincost[i,j]] 
      end
    end

     # example figures
    if region == example_figs_region 
      for sc_band_plot = 0:2
        e_f_centers["dtw$sc_band_plot"]=centers_[example_figs_n_clust,sc_band_plot+1,ind_mincost[example_figs_n_clust]]'
        e_f_weights["dtw$sc_band_plot"]=weights_[example_figs_n_clust,sc_band_plot+1,ind_mincost[example_figs_n_clust]]
      end 
    end

     #### k-shape ###########

     # read parameters
    param=DataFrame()
    try
      param = readtable(joinpath("outfiles",string("parameters_kshape_",region,".txt")))
    catch
      error("No input file parameters.txt exists in folder outfiles.")
    end

    n_clust_min=param[:n_clust_min][1]
    n_clust_max=param[:n_clust_max][1]
    n_init=param[:n_init][1]
    iterations=param[:iterations][1]
    region=param[:region][1]

    n_clust_ar = collect(n_clust_min:n_clust_max)

     # load saved JLD data
    saved_data_dict= load(string(joinpath("outfiles","aggregated_results_kshape_"),region,".jld2"))
     #unpack saved JLD data
     for (k,v) in saved_data_dict
       @eval $(Symbol(string(k,"_"))) = $v
     end

     #set revenue to the chosen problem type
    revenue_dict["kshape"]=[revenue_[problem_type][i] for i in 1:size(n_clust_ar,1)]
    cost_dict["kshape"] = [cost_[i] for i in 1:size(n_clust_ar,1)]

     # Find best cost index - save
    ind_mincost = zeros(Int,size(n_clust_ar,1))
    for i=1:size(n_clust_ar,1)
      ind_mincost[i] = findmin(cost_[i])[2] 
    end
    revenue_best["kshape"] = zeros(size(n_clust_ar,1))
    cost_best["kshape"] = zeros(size(n_clust_ar,1))
    for i=1:size(n_clust_ar,1)
        revenue_best["kshape"][i]=revenue_[problem_type][i][ind_mincost[i]] 
        cost_best["kshape"][i]=cost_[i][ind_mincost[i]] 
    end
    
     # example figures
    if region == example_figs_region 
      e_f_centers["kshape"]=centers_[example_figs_n_clust,ind_mincost[example_figs_n_clust]]
      e_f_weights["kshape"]=weights_[example_figs_n_clust,ind_mincost[example_figs_n_clust]]
    end

     ####### Figures ##############
   
 # plot clusters - possibly as heat map

    
    if region == example_figs_region && false 
      
      fig,ax_array = plt.subplots(2,1,sharex=true)#figsize=()
      subplot_clusters(e_f_centers["kmeans"],e_f_weights["kmeans"],ax_array[1,1];region=region,descr="kmeans")
      subplot_clusters(e_f_centers["kmedoids"],e_f_weights["kmedoids"],ax_array[1,1];region=region,descr="kmedoids",linestyle="--")
      ax_array[1,1]["legend"]()  
      ax_array[1,1]["set"](ylabel="EUR/MWh")
      # TODO also plot hierarchical just to check 
      subplot_clusters(e_f_centers["kshape"],e_f_weights["kshape"],ax_array[2,1];region=region,descr="kshape")
      subplot_clusters(e_f_centers["dtw1"],e_f_weights["dtw1"],ax_array[2,1];region=region,descr="dtw 1",linestyle="--")
      ax_array[2,1]["legend"]()  
      ax_array[2,1]["set"](ylabel="EUR/MWh")
      fig["subplots_adjust"](hspace=0.1)
      savefig(joinpath("plots","example_clusters_$region.eps"),format="eps")
      
    
      plot_clusters(e_f_centers["kmeans"],e_f_weights["kmeans"];region=region,descr="kmeans")
      plot_clusters(e_f_centers["kmedoids"],e_f_weights["kmedoids"];region=region,descr="kmedoids")
      plot_clusters(e_f_centers["kshape"],e_f_weights["kshape"];region=region,descr="kshape")
      plot_clusters(e_f_centers["dtw0"],e_f_weights["dtw0"];region=region,descr="dtw 0")
      plot_clusters(e_f_centers["dtw1"],e_f_weights["dtw1"];region=region,descr="dtw 1")
      plot_clusters(e_f_centers["dtw2"],e_f_weights["dtw2"];region=region,descr="dtw 2")
    end
 #break
 #break

    # rev vs SSE plots 
    if region == example_figs_region && problem_type=="battery"

      cost_rev_clouds = Dict()
      cost_rev_points = Array{Dict,1}()
      descr=string(joinpath("plots","cloud_kmeans_"),region,".png")

      cost_rev_clouds["cost"]=cost_dict["kmeans"]
      cost_rev_clouds["rev"] = revenue_dict["kmeans"]

       #push!(cost_rev_points,Dict("label"=>"Hierarchical centroid","cost"=>cost_dict["hier_centroid"],"rev"=>revenue_dict["hier_centroid"],"mec"=>"k","mew"=>2.0,"marker"=>"." ))
       # \TODO   --> add best kmeans
      push!(cost_rev_points,Dict("label"=>"k-means best","cost"=>cost_best["kmeans"],"rev"=>revenue_best["kmeans"],"mec"=>"k","mew"=>2.0,"marker"=>"s" ))
      push!(cost_rev_points,Dict("label"=>"Hierarchical centroid","cost"=>cost_dict["hier_centroid"],"rev"=>revenue_dict["hier_centroid"],"mec"=>"k","mew"=>3.0,"marker"=>"x" ))

      plot_SSE_rev(n_clust_ar, cost_rev_clouds, cost_rev_points, descr,revenue_orig_daily)
       

      # Medoid
       # k-medoids
      cost_rev_clouds = Dict()
      cost_rev_points = Array{Dict,1}()
      descr=string(joinpath("plots","cloud_kmedoids_"),region,".png")

      cost_rev_clouds["cost"]=cost_dict["kmedoids"]
      cost_rev_clouds["rev"] = revenue_dict["kmedoids"]

       # k-medoids exact
      push!(cost_rev_points,Dict("label"=>"k-medoids exact","cost"=>cost_dict["kmedoids_exact"],"rev"=>revenue_dict["kmedoids_exact"],"mec"=>"k","mew"=>2.0,"marker"=>"s" ))

       # hier medoid
      push!(cost_rev_points,Dict("label"=>"Hierarchical medoid","cost"=>cost_dict["hier_medoid"],"rev"=>revenue_dict["hier_medoid"],"mec"=>"k","mew"=>3.0,"marker"=>"x" ))

      plot_SSE_rev(n_clust_ar, cost_rev_clouds, cost_rev_points, descr,revenue_orig_daily;n_col=3)
    end


    ####### save relevant plot information rev vs. k
    for plot_type in plot_types
      plot_descr = "$region\_$problem_type\_$plot_type"

      # revenue vs. k - pre-sort
      clust_methods[plot_descr] = Array{Dict,1}()
      push!(clust_methods[plot_descr],Dict("name"=>"365 days", "rev"=> revenue_orig_daily*ones(length(n_clust_ar)),"color"=>"k","linestyle"=>"--","width"=>1.5))
      
      if plot_type == plot_types[1] # trad_cen  
        push!(clust_methods[plot_descr],Dict("name"=>"hierarchical centroid", "rev"=> revenue_best["hier_centroid"][:],"color"=>col.dblue,"linestyle"=>"-","width"=>1.5))
        push!(clust_methods[plot_descr],Dict("name"=>"k-means", "rev"=> revenue_best["kmeans"][:],"color"=>col.red,"linestyle"=>"-","width"=>1.5))
      elseif plot_type == plot_types[2] # trad_med
        push!(clust_methods[plot_descr],Dict("name"=>"k-medoids", "rev"=> revenue_best["kmedoids_exact"][:],"color"=>col.orange,"linestyle"=>"-","width"=>1.5))
        push!(clust_methods[plot_descr],Dict("name"=>"hierarchical medoid", "rev"=> revenue_best["hier_medoid"][:],"color"=>col.lblue,"linestyle"=>"-","width"=>1.5))
        push!(clust_methods[plot_descr],Dict("name"=>"k-means + medoid rep.", "rev"=> revenue_best["kmeans_medoidrep"][:],"color"=>col.purple,"linestyle"=>"-","width"=>1.5))
      elseif plot_type == plot_types[3] # shape
        push!(clust_methods[plot_descr],Dict("name"=>"k-shape", "rev"=> revenue_best["kshape"][:],"color"=>col.yellow,"linestyle"=>"-","width"=>1.5))
        push!(clust_methods[plot_descr],Dict("name"=>"DBA b=0", "rev"=> revenue_best["dtw"][:,1],"color"=>col.brown,"linestyle"=>"-","width"=>1.5))
        push!(clust_methods[plot_descr],Dict("name"=>"DBA b=1", "rev"=> revenue_best["dtw"][:,2],"color"=>col.brown,"linestyle"=>"--","width"=>1.5))
        push!(clust_methods[plot_descr],Dict("name"=>"DBA b=2", "rev"=> revenue_best["dtw"][:,3],"color"=>col.brown,"linestyle"=>":","width"=>1.5))
      end #plot_type
    end # plot_type in plot_types

 # todo: possibly add clouds here as well

 # end pre-sort of data
    
  end # problem_type in problem_types
end # region_ in regions

 # plot revenue vs. k 

 #subplot: https://stackoverflow.com/questions/23739277/how-should-i-pass-a-matplotlib-object-through-a-function-as-axis-axes-or-figur

fig,ax_array = plt.subplots(3,4,sharex=true,sharey=true)#figsize=()
n_row=0
n_col=0
for plot_type in plot_types
  n_row+=1
  n_col=0
  for problem_type in problem_types
    for region in regions
      n_col+=1
      plot_descr = "$region\_$problem_type\_$plot_type"
      # legend placement: 
      #https://stackoverflow.com/questions/4700614/how-to-put-the-legend-out-of-the-plot
      plot_k_rev_subplot(n_clust_ar,clust_methods[plot_descr],plot_descr,ax_array[n_row,n_col];save=false)
    end
  end
end
fig["subplots_adjust"](hspace=0.1)
fig["subplots_adjust"](wspace=0.1)
ax_array[1,1]["set"](xticks=n_clust_ar)
ax_array[1,1]["set"](ylabel="Centroid\nObjective value")
ax_array[2,1]["set"](ylabel="Medoid\nObjective value")
ax_array[3,1]["set"](xlabel="k",ylabel="Shape\nObjective value")
ax_array[3,2]["set"](xlabel="k")
ax_array[3,3]["set"](xlabel="k")
ax_array[3,4]["set"](xlabel="k")

ax_array[1,1]["set_title"]("Battery\nGER")
ax_array[1,2]["set_title"]("Battery\nCA")
ax_array[1,3]["set_title"]("Gas turbine\nGER")
ax_array[1,4]["set_title"]("Gas turbine\nCA")

savefig(joinpath("plots","rev_vs_k.eps"),format="eps")


