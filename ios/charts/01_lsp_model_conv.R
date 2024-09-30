a <- grViz("digraph {

graph [layout = dot,ontname = 'helvetica',  nodesep=0.1, overlap='prism1000', rankdir = TB]

# define the global styles of the nodes. We can override these in box if we wish

node [shape = cylinder, style = filled, fillcolor = LightBlue]
modis [label = 'M*D13Q1 \n VI 250 m [Didan, 2021]']
landsat [label = 'Landsat Surface Reflectance \n Collection 2 VI 30 m [USGS]']
cr2 [label = 'CR2MET Temperature and Precipitation \n v2.5 0.05 degrees [Boisier, 2023]']
phenChile [label = 'PhenChile monitoring network \n GCC data v1.0 [Chávez et al., 2024]']

node [shape = rectangle, style = filled, fillcolor = Linen]
process1 [label =  'Quality assesment \n Cleaning low quality data (clouds, cloud, shadows, artifacts)']
process2 [label = 'Time series gap-filling']
process3 [label = 'Growing season identification']
decision1 [label =  'Austral summer peak?', shape = diamond, fillcolor = Tomato]
yes1 [label = 'Yes', shape = circle]
no1 [label = 'No', shape = circle]

decision2 [label =  'Has seasonality?', shape = diamond, fillcolor = Tomato]
yes2 [label = 'Yes', shape = circle]
no2 [label = 'No', shape = circle]
process4a [label = 'GS: January 1st - December 31st']
process4b [label = 'GS: july 1st - June 30th']
process4c [label = 'Model fit \n Beck logistics (Beck et al., 2006) | Elmore logistics (Elmore et al., 2012)']

process5 [label = 'Phenometrics extraction \n Threshold and Derivative methods']
process6 [label = 'Metrics validation']
process7 [label = 'Climatic analysis']
resultado1 [label= 'LSP maps']

# npphen processing
node [shape = rectangle, style = filled, fillcolor = Linen]

process8 [label = 'Temporal KDE \n 5-year moving window']
process9 [label = 'Extraction of most probable \n daily phenological curve']
process10 [label = 'Dynamic growing season \n center arround max VI value']


# edge definitions with the node IDs
# conventional
{modis landsat}  -> process1 -> process2 -> decision2 -> {yes2 no2} 
no2 -> Remove
yes2 -> process3 -> decision1 -> {yes1 no1} 

no1 -> process4a 
yes1 -> process4b

{process4b process4a} -> process4c -> process5 -> resultado1
phenChile -> process6 -> {process5}
phenChile -> process7  
cr2 -> process7 -> resultado1

# npphen approach
process1 -> process8 -> process9 -> process10 -> process5

# Subplots

subgraph cluster_1{
graph[shape = rectangle]
         style = rounded
         bgcolor = FloralWhite
         label = 'Conventional analysis'
    
      modis landsat process1 process2 decision2 {yes2 no2} 
      Remove
      process3  decision1  {yes1 no1} 
      process4b process4a process4c process5 resultado1
}

subgraph cluster_2 {
graph[shape = rectangle]
         style = rounded
         bgcolor = FloralWhite
         label = 'Validation and climate analysis'
    phenChile process6 resultado1 process5 cr2 process7  
}

subgraph cluster_3 {
graph[shape = rectangle]
         style = rounded
         bgcolor = FloralWhite
         label = 'Climate'
    cr2 process7 resultado1     
}

subgraph cluster_4 {
graph[shape = rectangle]
         style = rounded
         bgcolor = FloralWhite
         label = 'Non-parametric analysis'
    process1 process8 process9 process5 resultado1    
}

}")

