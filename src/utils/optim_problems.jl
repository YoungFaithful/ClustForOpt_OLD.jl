# optimization problems

"""
function run_battery_opt(el_price, weight=1, prnt=false)

operational battery storage optimization problem
"""
function run_battery_opt(el_price, weight=1, prnt=false)
  num_periods = size(el_price,2); # number of periods, 1day, one week, etc.
  num_hours = size(el_price,1); # hours per period (24 per day, 48 per 2days)

  # time steps
  del_t = 1; # hour

  # example battery Southern California Edison
  P_battery = 100; # MW
  E_battery = 400; # MWh
  eff_Storage_in = 0.95;
  eff_Storage_out = 0.95;
  #Stor_init = 0.5;

  # optimization
  # Sets
  # time
  t_max = num_hours;

  E_in_arr = zeros(num_hours,num_periods)
  E_out_arr = zeros(num_hours,num_periods)
  stor = zeros(num_hours +1,num_periods)

  obj = zeros(num_periods);
  m= Model(solver=ClpSolver() )

  # hourly energy output
  @variable(m, E_out[t=1:t_max] >= 0) # kWh
  # hourly energy input
  @variable(m, E_in[t=1:t_max] >= 0) # kWh
  # storage level
  @variable(m, Stor_lev[t=1:t_max+1] >= 0) # kWh

  @variable(m,0 <= Stor_init <= 1) # this as a variable ensures

  # maximum battery power
  for t=1:t_max
    @constraint(m, E_out[t] <= P_battery*del_t)
    @constraint(m, E_in[t] <= P_battery*del_t)
  end

  # maximum storage level
  for t=1:t_max+1
    @constraint(m, Stor_lev[t] <= E_battery)
  end

  # battery energy balance
  for t=1:t_max
    @constraint(m,Stor_lev[t+1] == Stor_lev[t] + eff_Storage_in*del_t*E_in[t]-(1/eff_Storage_out)*del_t*E_out[t])
  end

  # initial storage level
  @constraint(m,Stor_lev[1] == Stor_init*E_battery)
  @constraint(m,Stor_lev[t_max+1] >= Stor_lev[1])

  for i =1:num_periods
    #objective
    @objective(m, Max, sum((E_out[t] - E_in[t])*el_price[t,i] for t=1:t_max) )
    status = solve(m)

    if weight ==1
      obj[i] = getobjectivevalue(m)
    else
      obj[i] = getobjectivevalue(m) * weight[i] * 365
    end
    E_in_arr[:,i] = getvalue(E_in)'
    E_out_arr[:,i] = getvalue(E_out)
    stor[:,i] = getvalue(Stor_lev)
  end

  # plots
  if(prnt)
    figure()
    for i=1:num_periods
      plt.plot(stor[:,i], label=string("stor lev: ", i))
      plt.legend()
    end

    figure()
    for i=1:num_periods
      plt.plot(E_in_arr[:,i],label=string("E_in: ",i))
      plt.plot(E_out_arr[:,i], label=string("E_out: ",i))
      plt.legend()
    end
  end # prnt

  return obj
end # run_battery_opt()

 ###

"""
function run_gas_opt(el_price, weight=1, country = "", prnt=false)

operational gas turbine optimization problem
"""
function run_gas_opt(el_price, weight=1, country = "", prnt=false)
  
  num_periods = size(el_price,2); # number of periods, 1day, one week, etc.
  num_hours = size(el_price,1); # hours per period (24 per day, 48 per 2days)

  # time steps
  del_t = 1; # hour


  # example gas turbine
  P_gt = 100; # MW
  eta_t = 0.6; # 40 % efficiency
  if country == "GER"
    gas_price = 24.65  # EUR/MWh    7.6$/GJ = 27.36 $/MWh=24.65EUR/MWh with 2015 conversion rate
  elseif country == "CA"
    gas_price  = 14.40   # $/MWh        4$/GJ = 14.4 $/MWh
  end

  # optimization
  # Sets
  # time
  t_max = num_hours;

  E_out_arr = zeros(num_hours,num_periods)

  obj = zeros(num_periods);
  m= Model(solver=ClpSolver() )

  # hourly energy output
  @variable(m, 0 <= E_out[t=1:t_max] <= P_gt) # MWh

  for i =1:num_periods
    #objective
    @objective(m, Max, sum(E_out[t]*el_price[t,i] - 1/eta_t*E_out[t]*gas_price for t=1:t_max) )
    status = solve(m)

    if weight ==1
      obj[i] = getobjectivevalue(m)
    else
      obj[i] = getobjectivevalue(m) * weight[i] * 365
    end
    E_out_arr[:,i] = getvalue(E_out)
  end

  # plots
  if(prnt)
    ut = zeros(num_periods)
    figure()
    for i=1:num_periods
        ut[i] = sum(E_out_arr[:,i])/(length(E_out_arr[:,i])*P_gt)
        plt.plot(ut)
        plt.title("daily utilization factor")
    end

    figure()
    for i=1:5 #num_periods
      plt.plot(E_out_arr[:,i], label=string("E_out: ",i))
      plt.legend()
    end
  end # prnt

  return obj
end # run_gas_opt()


"""
function run_opt(problem_type,el_price,weight=1,country="",prnt=false)

Wrapper function for type of optimization problem
"""
function run_opt(problem_type,el_price,weight=1,country="",prnt=false)

  if problem_type == "battery"
    return run_battery_opt(el_price, weight, prnt)
  elseif problem_type == "gas_turbine"
    return run_gas_opt(el_price,weight,country,prnt) 
  else
    error("optimization problem_type ",problem_type," does not exist")
  end

end # run_opt
