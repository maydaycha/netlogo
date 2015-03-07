// (C) Uri Wilensky. https://github.com/NetLogo/NW-Extension

package org.nlogo.extensions.nw.jung

import org.nlogo.agent.AgentSet
import org.nlogo.util.MersenneTwisterFast

import edu.uci.ics.jung.algorithms.generators.Lattice2DGenerator
import edu.uci.ics.jung.algorithms.generators.random.BarabasiAlbertGenerator
import edu.uci.ics.jung.algorithms.generators.random.KleinbergSmallWorldGenerator

class Generator(
  turtleBreed: AgentSet,
  linkBreed: AgentSet) {

  type V = DummyGraph.Vertex
  type E = DummyGraph.Edge

  lazy val graphFactory = factoryFor[V, E](linkBreed)
  lazy val undirectedGraphFactory = undirectedFactory[V, E]
  lazy val edgeFactory = DummyGraph.edgeFactory
  lazy val vertexFactory = DummyGraph.vertexFactory

  def lattice2D(rowCount: Int, colCount: Int, isToroidal: Boolean, rng: MersenneTwisterFast) =
    DummyGraph.importToNetLogo(new Lattice2DGenerator(
      graphFactory, vertexFactory, edgeFactory,
      rowCount, colCount, isToroidal)
      .create, turtleBreed, linkBreed, rng)

  def barabasiAlbert(nbVertices: Int, rng: MersenneTwisterFast) = {
    val gen = new BarabasiAlbertGenerator(
      graphFactory, vertexFactory, edgeFactory,
      1, 1, new java.util.HashSet[V])

    // use reflection to set our own rng
    val mRandomField = gen.getClass.getDeclaredField("mRandom")
    mRandomField.setAccessible(true)
    mRandomField.set(gen, rng)

    while (gen.create.getVertexCount < nbVertices)
      gen.evolveGraph(1)
    DummyGraph.importToNetLogo(gen.create, turtleBreed, linkBreed, rng, sorted = true)
  }

  def kleinbergSmallWorld(rowCount: Int, colCount: Int,
    clusteringExponent: Double, isToroidal: Boolean, rng: MersenneTwisterFast) = {
    val gen = new KleinbergSmallWorldGenerator(
      undirectedGraphFactory, vertexFactory, edgeFactory,
      rowCount, colCount, clusteringExponent, isToroidal)
    gen.setRandom(rng)
    DummyGraph.importToNetLogo(gen.create, turtleBreed, linkBreed, rng)
  }
}

