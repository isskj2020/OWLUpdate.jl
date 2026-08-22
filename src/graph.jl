using Graphs

function repair_cyclic_graph(dag::SimpleDiGraph)
    cyclic_vertices = Set{Int}()
    for components in strongly_connected_components(dag)
        if length(components) > 1
            union!(cyclic_vertices, components)
        end
    end
    if !isempty(cyclic_vertices)
        @warn "The graph is cyclic. Node depths are incorrect."
        g = SimpleDiGraph(nv(dag))
        for e in edges(dag)
            source = src(e)
            destination = dst(e)

            if !(source in cyclic_vertices || destination in cyclic_vertices)
                add_edge!(g, source, destination)
            end
        end
        return g
    end
    return dag
end

function dfs_descendants(dag::SimpleDiGraph, x::Int)
    visited = Set{Int}()
    stack = [x]
    while !isempty(stack)
        v = pop!(stack)
        for n in outneighbors(dag, v)
            if n ∉ visited
                push!(visited, n)
                push!(stack, n)
            end
        end
    end
    return visited
end

function dfs_ancestors(dag::SimpleDiGraph, x::Int; bounds::Set{Int})
    visited = Set{Int}()
    stack = [x]
    while !isempty(stack)
        v = pop!(stack)
        if v in bounds
            continue
        end
        for n in inneighbors(dag, v)
            if n ∉ visited
                push!(visited, n)
                push!(stack, n)
            end
        end
    end
    return visited
end
