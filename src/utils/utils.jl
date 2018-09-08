#

"""
function get_EUR_to_USD(region::String)

  convert Euro to US dollars
  introduced because the clusters generated by the python script are in EUR for GER
"""
function get_EUR_to_USD(region::String)
   if region =="GER"
     ret = 1.109729
   else
     ret =1
   end
   return ret
end

"""
function load_pricedata(region::String)

Loads price data from either GER or CA  
"""
function load_pricedata(region::String)
  wor_dir = pwd()
  cd(dirname(@__FILE__)) # change working directory to current file
  if region =="CA"
    region_str = ""
    region_data = normpath(joinpath(pwd(),"..","..","data","el_prices","ca_2015_orig.txt"))
  elseif region == "GER"
    region_str = "GER_"
    region_data = normpath(joinpath(pwd(),"..","..","data","el_prices","GER_2015_elPrice.txt"))
  else
    error("Region ",region," not defined.")
  end
  data_orig = Array(readtable(region_data, separator = '\t', header = false))
  data_orig_daily = reshape(data_orig,24,365)
  cd(wor_dir) # change working directory to old previous file's dir
  return data_orig_daily
end #load_pricedata


  """
function sort_centers(centers::Array,weights::Array)
 
  centers: hours x days e.g.[24x9] 
  weights: days [e.g. 9], unsorted 
   sorts the centers by weights
  """
function sort_centers(centers::Array,weights::Array)
  i_w = sortperm(-weights)   # large to small (-)
  weights_sorted = weights[i_w]
  centers_sorted = centers[:,i_w]
  return centers_sorted, weights_sorted
end # function

"""
function z_normalize(data;scope="full")

z-normalize data with mean and sdv by hour

data: input format: (1st dimension: 24 hours, 2nd dimension: # of days)
scope: "full": one mean and sdv for the full data set; "hourly": univariate scaling: each hour is scaled seperately; "sequence": sequence based scaling
"""
function z_normalize(data;scope="full")
  if scope == "sequence"
    seq_mean = zeros(size(data)[2])
    seq_sdv = zeros(size(data)[2])
    data_norm = zeros(size(data)) 
    for i=1:size(data)[2]
      seq_mean[i] = mean(data[:,i])
      seq_sdv[i] = std(data[:,i])
      isnan(seq_sdv[i]) &&  (seq_sdv[i] =1)
      data_norm[:,i] = data[:,i] - seq_mean[i]
      data_norm[:,i] = data_norm[:,i]/seq_sdv[i]
    end
    return data_norm,seq_mean,seq_sdv
  elseif scope == "hourly"
    hourly_mean = zeros(size(data)[1])
    hourly_sdv = zeros(size(data)[1])
    data_norm = zeros(size(data)) 
    for i=1:size(data)[1]
      hourly_mean[i] = mean(data[i,:])
      hourly_sdv[i] = std(data[i,:])
      isnan(hourly_sdv[i]) &&  (hourly_sdv[i] =1)
      data_norm[i,:] = data[i,:] - hourly_mean[i]
      data_norm[i,:] = data_norm[i,:]/hourly_sdv[i]
    end
    return data_norm, hourly_mean, hourly_sdv
  elseif scope == "full"
    hourly_mean = mean(data)*ones(size(data)[1])
    hourly_sdv = std(data)*ones(size(data)[1])
    data_norm = (data-hourly_mean[1])/hourly_sdv[1]
    return data_norm, hourly_mean, hourly_sdv
  else
    error("scope _ ",scope," _ not defined.")
  end
end # function z_normalize

"""
function undo_z_normalize(data_norm, mn, sdv; idx=[])

undo z-normalization data with mean and sdv by hour
normalized data: input format: (1st dimension: 24 hours, 2nd dimension: # of days)
hourly_mean ; 24 hour vector with hourly means
hourly_sdv; 24 hour vector with hourly standard deviations
"""
function undo_z_normalize(data_norm, mn, sdv; idx=[])
  if size(data_norm,1) == size(mn,1) # hourly - even if idx is provided, doesn't matter if it is hourly
    data = data_norm .* sdv + mn * ones(size(data_norm)[2])'
    return data
  elseif !isempty(idx) && size(data_norm,2) == maximum(idx) # sequence based
    # we obtain mean and sdv for each day, but need mean and sdv for each centroid - take average mean and sdv for each cluster
    summed_mean = zeros(size(data_norm,2)) 
    summed_sdv = zeros(size(data_norm,2))
    for k=1:size(data_norm,2)
      mn_temp = mn[idx.==k]
      sdv_temp = sdv[idx.==k]
      summed_mean[k] = sum(mn_temp)/length(mn_temp) 
      summed_sdv[k] = sum(sdv_temp)/length(sdv_temp)
    end
    data = data_norm * Diagonal(summed_sdv) +  ones(size(data_norm,1)) * summed_mean'
    return data
  elseif isempty(idx)
    error("no idx provided in undo_z_normalize")
  end
end

"""
function sakoe_chiba_band(r::Int,l::Int)

calculates the minimum and maximum allowed indices for a lxl windowed matrix
for the sakoe chiba band (see Sakoe Chiba, 1978).
Input: radius r, such that |i(k)-j(k)| <= r
length l: dimension 2 of the matrix
"""
function sakoe_chiba_band(r::Int,l::Int)
  i2min = Int[]
  i2max = Int[]
  for i=1:l
    push!(i2min,max(1,i-r))
    push!(i2max,min(l,i+r))
  end
  return i2min, i2max
end

"""
function calc_SSE(data::Array,centers::Array,assignments::Array)

calculates Sum of Squared Errors between cluster representations and the data
"""
function calc_SSE(data::Array,centers::Array,assignments::Array)
  k=size(centers,2) # number of clusters
  n_periods =size(data,2)  
  SSE_sum = zeros(k)
  for i=1:n_periods
    SSE_sum[assignments[i]] += sqeuclidean(data[:,i],centers[:,assignments[i]])
  end 
  return sum(SSE_sum)
end # calc_SSE 

"""
function find_medoids(data::Array,centers::Array,assignments::Array)

Given the data and cluster centroids and their respective assignments, this function finds
the medoids that are closest to the cluster center. 
"""
function find_medoids(data::Array,centers::Array,assignments::Array)
  k=size(centers,2) #number of clusters
  n_periods =size(data,2)  
  SSE=Float64[]
  for i=1:k
    push!(SSE,Inf)
  end
  medoids=zeros(centers)
  for i=1:n_periods
    d = sqeuclidean(data[:,i],centers[:,assignments[i]])
    if d < SSE[assignments[i]]
      medoids[:,assignments[i]] = data[:,i]
    end
  end
  return medoids
end

"""
function resize_medoids(data::Array,centers::Array,weights::Array,assignments::Array)

Takes in centers (typically medoids) and normalizes them such that for all clusters the average of the cluster is the same as the average of the respective original data that belongs to that cluster.

In order to use this method of the resize function, add assignments to the function call (e.g. clustids[5,1]).  
"""
function resize_medoids(data::Array,centers::Array,weights::Array,assignments::Array)
    new_centers = zeros(centers)
    for k=1:size(centers)[2] # number of clusters
       is_in_k = assignments.==k
       n = sum(is_in_k)
       new_centers[:,k]=resize_medoids(reshape(data[:,is_in_k],:,n),reshape(centers[:,k] , : ,1),[1.0])# reshape is used for the side case with only one vector, so that resulting vector is 24x1 instead of 24-element 
    end
    return new_centers
end


"""
function resize_medoids(data::Array,centers::Array,weights::Array)

Takes in centers (typically medoids) and normalizes them such that the yearly average of the clustered data is the same as the yearly average of the original data.
"""
function resize_medoids(data::Array,centers::Array,weights::Array)
    mu_data = sum(data)
    mu_clust = 0
    for k=1:size(centers)[2]
      mu_clust += weights[k]*sum(centers[:,k]) # 0<=weights<=1
    end
    mu_clust *= size(data)[2]
    mu_data_mu_clust = mu_data/mu_clust
    new_centers = centers* mu_data_mu_clust 
    #println(mu_data_mu_clust)
    return new_centers 
end

