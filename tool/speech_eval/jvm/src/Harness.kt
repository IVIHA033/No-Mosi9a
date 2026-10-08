import ai.onnxruntime.OrtEnvironment
import com.nomosi9a.app.engine.DpdfnetDenoiser
import com.nomosi9a.app.engine.SileroVad
import com.nomosi9a.app.engine.SpeechGuard
import java.io.File
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.channels.FileChannel
import java.nio.file.StandardOpenOption

/** Runs the app's engine classes on a raw float32 mono file: harness <model.onnx> <vad.onnx|-> <level> <in.f32> <out.f32> */
fun main(args: Array<String>) {
    val (modelPath, vadPath, level, inPath, outPath) = args
    val env = OrtEnvironment.getEnvironment()
    fun map(p: String): ByteBuffer = FileChannel.open(File(p).toPath(), StandardOpenOption.READ).use {
        it.map(FileChannel.MapMode.READ_ONLY, 0, it.size())
    }
    val vad = if (vadPath == "-") null else SileroVad.load(env, map(vadPath)) to SileroVad.load(env, map(vadPath))
    val d = DpdfnetDenoiser.load(env, map(modelPath), vad)
    d.guard?.level = SpeechGuard.Level.fromId(level)
    val bytes = File(inPath).readBytes()
    val x = ByteBuffer.wrap(bytes).order(ByteOrder.LITTLE_ENDIAN).asFloatBuffer()
    val hop = d.hopSize
    val n = x.remaining() / hop
    val input = FloatArray(hop)
    val output = FloatArray(hop)
    val out = ByteBuffer.allocate(n * hop * 4).order(ByteOrder.LITTLE_ENDIAN)
    val speaking = StringBuilder()
    val t0 = System.nanoTime()
    for (t in 0 until n) {
        x.get(input)
        d.process(input, output)
        for (v in output) out.putFloat(v)
        speaking.append(if (d.guard?.speaking == true) '1' else '0')
    }
    val ms = (System.nanoTime() - t0) / 1e6 / n
    File(outPath).writeBytes(out.array())
    File("$outPath.speaking").writeText(speaking.toString())
    System.err.println("hops=$n sr=${d.sampleRate} %.3f ms/hop".format(ms))
    d.close()
}
