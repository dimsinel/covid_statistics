using DrWatson
@quickactivate "@covstat"

# Here you may include files from the source directory
include(srcdir("dummy_src_file.jl"))

using RDatasets, MLJ, Pipe

## https://alan-turing-institute.github.io/MLJ.jl/v0.11/getting_started/#Getting-Started-1

iris = RDatasets.dataset("datasets", "iris"); # a DataFrame
y, X = unpack(iris, ==(:Species), colname -> true);

mods = models(matching(X,y))
for x in mods
    for naem in [:name, :package_name]
        if  occursin("idg",x[naem]) 
            @show x[[:name, :package_name]]
        end 
    end
end

tree_model = @load DecisionTreeClassifier verbosity=1
