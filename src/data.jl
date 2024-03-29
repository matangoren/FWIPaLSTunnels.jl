using PyPlot
using Distributions: Uniform

function generateData(n, m; linear=false)
    h1 = Int64(floor(n[1] / 8))
    h2 = Int64(floor(n[2] / 16))

    data = Matrix{Float64}[];

    for i=1:m
        if linear
            model = get2DVelocityLinearModel(n)
        else
            model = ones(Float64, n...)
        end

        num_levels = rand(1:2)
        level_info = []
        for i=1:num_levels
            s = rand(1:4)
            t = rand(s+3:7)
            start_index = 1 + s*h1 - rand(0:4:16);
            end_index = t*h1 + rand(0:4:16);

            if i == 1
                d = rand(3:5);
                model[s*h1+1:s*h1+rand(8:4:16), 1:d*h2] .= 10.0;
                model[t*h1-rand(8:4:16)+1:t*h1, 1:d*h2] .= 10.0;
            else
                prev_start, prev_end, prev_d = level_info[end];
                d = prev_d + 4 + rand(0:1);
                d_s = 1; d_t = 1;
                if  prev_start <= s*h1 <= prev_end
                    d_s += prev_d*h2-16
                end
                if prev_start <= t*h1 <= prev_end
                    d_t += prev_d*h2-16
                end
                model[s*h1+1:s*h1+rand(8:4:16), d_s:d*h2] .= 10.0;
                model[t*h1-rand(8:4:16)+1:t*h1, d_t:d*h2] .= 10.0;
            end
            append!(level_info, [(start_index, end_index, d)])

            model[start_index:end_index, d*h2-16+1:d*h2] .= 10.0;
            model[start_index:(s+1)*h1, d*h2-rand(16:8:32)+1:d*h2 + rand(0:8:16)] .= 10;
            model[(t-1)*h1+1:end_index, d*h2-rand(16:8:32)+1:d*h2 + rand(0:8:16)] .= 10;            
        end

        figure()
        imshow(model',clim=[1.5,4.5]); colorbar();
        append!(data, [model])
    end
end


function get2DVelocityLinearModel(n; top_lb=1.65, top_ub=1.75, bottom_lb=3.0, bottom_ub=4.0, absorbing_val=1.5)
    velocity_model = zeros(Float64, n[1]+1, n[2]+1)
    # adding sea layers
    num_layers = rand(2:7)
    velocity_model[:,1:num_layers] .= absorbing_val


    top_val = rand(Uniform(top_lb, top_ub))
    bottom_val = rand(Uniform(bottom_lb, bottom_ub))
    linear_model = (range(top_val,stop=bottom_val,length=n[2]+1-num_layers)) * ((ones(n[1]+1)'))

    velocity_model[:,num_layers+1:end] = linear_model'
    
    return velocity_model
end

function get2DSlownessLinearModel(n; top_lb=1.65, top_ub=1.75, bottom_lb=2.5, bottom_ub=3.5, absorbing_val=1.5, normalized=false)
    velocity_model = get2DVelocityLinearModel(n;top_lb=top_lb, top_ub=top_ub, bottom_lb=bottom_lb, bottom_ub=bottom_ub, absorbing_val=absorbing_val)
    slowness_model = velocityToSlowness(velocity_model)

    c = 1.0
    if normalized
        c = maximum(slowness_model)
        slowness_model = slowness_model ./ c
    end
    return slowness_model, c
end

velocityToSlowness(v::Array) = r_type.(1.0./(v.+1e-16))