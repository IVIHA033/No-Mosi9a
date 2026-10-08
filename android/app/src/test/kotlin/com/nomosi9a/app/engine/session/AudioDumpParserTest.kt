package com.nomosi9a.app.engine.session

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class AudioDumpParserTest {

    /** Shape of `dumpsys media.audio_policy` on Android 13-16. */
    private val policy13 = """
        Outputs dump:
        - Output 13 dump:
         Latency: 18
         Devices [ type:AUDIO_DEVICE_OUT_SPEAKER, @:speaker ]
         3 Clients:
          Port ID: 57; Session ID: 12345; uid 10200; State: Active
           - Format: 00000001 Sampling rate: 48000 Channels: 00000003
           - Attributes: { Content type: AUDIO_CONTENT_TYPE_MOVIE Usage: AUDIO_USAGE_MEDIA Source: AUDIO_SOURCE_DEFAULT Flags: 0x800 Tags:  }
           - Preferred Device Id: 0
          Port ID: 61; Session ID: 12409; uid 10250; State: Inactive
           - Attributes: { Content type: AUDIO_CONTENT_TYPE_SONIFICATION Usage: AUDIO_USAGE_NOTIFICATION Source: AUDIO_SOURCE_DEFAULT Flags: 0x0 Tags:  }
          Port ID: 70; Session ID: 12500; uid 10300; State: Active
           - Attributes: { Content type: AUDIO_CONTENT_TYPE_MUSIC Usage: AUDIO_USAGE_MEDIA Source: AUDIO_SOURCE_DEFAULT Flags: 0x400 Tags:  }
        Inputs dump:
        - Input 22 dump:
          Port ID: 80; Session ID: 12600; uid 10400; State: Active
           - Attributes: { Content type: AUDIO_CONTENT_TYPE_UNKNOWN Usage: AUDIO_USAGE_UNKNOWN Source: AUDIO_SOURCE_MIC Flags: 0x0 Tags:  }
        Effects:
          ID: 3
          Session: 12345
        Allow playback capture log:
          Package manager errors: 0
          - uid=10200, allowPlaybackCapture=true, packageName=com.google.android.youtube
          - uid=10350, allowPlaybackCapture=false, packageName=com.spotify.music
    """.trimIndent()

    /** Shape of the same dump on Android 10-12. */
    private val policy10 = """
         2 Clients:
          Client 1:
           - Port Id: 12 Session Id: 993 UID: 10123
           - Format: 00000001 Sampling rate: 44100 Channels: 00000003
           - Attributes: { Content type: AUDIO_CONTENT_TYPE_MUSIC Usage: AUDIO_USAGE_MEDIA Source: AUDIO_SOURCE_DEFAULT Flags: 0x0 Tags:  }
           - Preferred Device Id: 00000000
           - State: Active
          Client 2:
           - Port Id: 14 Session Id: 1001 UID: 10150
           - Attributes: { Content type: AUDIO_CONTENT_TYPE_UNKNOWN Usage: AUDIO_USAGE_GAME Source: AUDIO_SOURCE_DEFAULT Flags: 0x0 Tags:  }
           - State: Inactive
    """.trimIndent()

    /** `dumpsys audio`, "playback activity as reported through PlayerBase". */
    private val audioService = """
        playback activity as reported through PlayerBase:
          AudioPlaybackConfiguration piid:151 deviceId:3 type:android.media.AudioTrack u/pid:10200/5432 state:started attr:AudioAttributes: usage=USAGE_MEDIA content=CONTENT_TYPE_MOVIE flags=0x800 tags= bundle=null sessionId:12345 mutedState:
          AudioPlaybackConfiguration piid:159 deviceId:0 type:android.media.SoundPool u/pid:1000/1234 state:idle attr:AudioAttributes: usage=USAGE_ASSISTANCE_SONIFICATION content=CONTENT_TYPE_SONIFICATION flags=0x0 tags= bundle=null sessionId:0
          AudioPlaybackConfiguration piid:163 deviceId:3 type:android.media.AudioTrack u/pid:10300/777 state:paused attr:AudioAttributes: usage=USAGE_GAME content=CONTENT_TYPE_UNKNOWN flags=0x400 tags= bundle=null sessionId:12701
          AudioPlaybackConfiguration piid:170 deviceId:3 type:android.media.AudioTrack u/pid:10301/778 state:released attr:AudioAttributes: usage=USAGE_MEDIA content=CONTENT_TYPE_MUSIC flags=0x0 tags= bundle=null sessionId:12800
    """.trimIndent()


    /** Captured from an Android 15 (API 35) emulator while TestPlayer and the engine were running. */
    private val policy15Real = """
           - AudioTrack clients (3):
              1. Port ID: 15; Session ID: 97; uid 1000; State: Inactive
                 AUDIO_FORMAT_PCM_16_BIT; 48000; Channel mask: 0x3
                 Attributes: { Content type: AUDIO_CONTENT_TYPE_SONIFICATION Usage: AUDIO_USAGE_ASSISTANCE_SONIFICATION Source: AUDIO_SOURCE_DEFAULT Flags: 0x900 Tags:  }
                 Stream: 1; Flags: 00000004; Refcount: 0; InternalMute: No
              2. Port ID: 22; Session ID: 113; uid 10207; State: Active
                 AUDIO_FORMAT_PCM_FLOAT; 48000; Channel mask: 0x1
                 Attributes: { Content type: AUDIO_CONTENT_TYPE_MOVIE Usage: AUDIO_USAGE_MEDIA Source: AUDIO_SOURCE_INVALID Flags: 0xe00 Tags:  }
                 Stream: 3; Flags: 00000008; Refcount: 1; InternalMute: No
              3. Port ID: 27; Session ID: 121; uid 10208; State: Active
                 AUDIO_FORMAT_PCM_16_BIT; 48000; Channel mask: 0x1
                 Attributes: { Content type: AUDIO_CONTENT_TYPE_MOVIE Usage: AUDIO_USAGE_MEDIA Source: AUDIO_SOURCE_INVALID Flags: 0x800 Tags:  }
                 Stream: 3; Flags: 00000008; Refcount: 1; InternalMute: No
               DAP Secondary Outputs: 29,
           - AudioTrack active (stream) clients (2):
              id 1: Port ID: 27; Session ID: 121; uid 10208; State: Active
                    Attributes: { Content type: AUDIO_CONTENT_TYPE_MOVIE Usage: AUDIO_USAGE_MEDIA Source: AUDIO_SOURCE_INVALID Flags: 0x800 Tags:  }
             AudioRecord Clients (1):
              1. Port ID: 21; Session ID: 105; uid 10207; State: Active
                 AUDIO_FORMAT_PCM_FLOAT; 48000; Channel mask: 0x10
                 Attributes: { Content type: AUDIO_CONTENT_TYPE_UNKNOWN Usage: AUDIO_USAGE_UNKNOWN Source: AUDIO_SOURCE_REMOTE_SUBMIX Flags: 0x800 Tags: addr=584579369:ap:0mixp:0 }
                 Source: 8; Flags: 00000000; is soundtrigger: 0
          - uid= 1000, allowPlaybackCapture=true , packageName=android
          - uid=10208, allowPlaybackCapture=true , packageName=com.nomosi9a.testplayer
    """.trimIndent()

    /** `dumpsys media.audio_flinger` on Android 15 after the engine was force-stopped. */
    private val flinger15Orphans = """
          1 Effect Chains
            2 effects for session 145
        	In buffer    Out buffer                           Active tracks:
        	0x7bf6ba9000   0x7bf6bac000 -> 0xb400007b301e0020   1
        	Effect ID 43:
        		Session State Registered Internal Enabled Suspended:
        		00145   003   n          y        y       n
        		Descriptor:
        		- UUID: 119341a0-8469-11df-81f9-0002a5d5c51b
        		- TYPE: 09e8ede0-ddde-11db-b4f6-0002a5d5c51b
        		- name: Volume
        		0 Clients:
        			  Pid Priority Ctrl Locked client server
        	Effect ID 43 HAL dump:
        EffectHal::threadLoop n=9793 ave=0.0288347
        	Effect ID 35:
        		Session State Registered Internal Enabled Suspended:
        		00145   003   n          y        y       n
        		Descriptor:
        		- UUID: e0e6539b-1781-7261-676f-6d7573696340
        		- TYPE: 7261676f-6d75-7369-6364-28e2fd3ac39e
        		- name: Dynamics Processing
        		0 Clients:
        			  Pid Priority Ctrl Locked client server
            1 effects for session 201
        	Effect ID 50:
        		Session State Registered Internal Enabled Suspended:
        		00201   003   y          n        y       n
        		Descriptor:
        		- TYPE: 7261676f-6d75-7369-6364-28e2fd3ac39e
        		- name: Dynamics Processing
        		1 Clients:
        			  Pid Priority Ctrl Locked client server
        			 8293    2147483647  yes    yes      0      0
    """.trimIndent()

    @Test
    fun findsOnlyOrphanedMuteEffects() {
        val dp = AudioDumpParser.parseOrphanEffects(flinger15Orphans, setOf("7261676f-6d75-7369-6364-28e2fd3ac39e"))
        val volume = AudioDumpParser.parseOrphanEffects(flinger15Orphans, setOf("09e8ede0-ddde-11db-b4f6-0002a5d5c51b"))
        // Session 201 still has a live client: it must not be touched.
        assertEquals(setOf(145), dp)
        assertEquals(setOf(145), volume)
        assertTrue(AudioDumpParser.parseOrphanEffects("", setOf("x")).isEmpty())
    }

    @Test
    fun parsesAndroid13PolicyDump() {
        val dump = AudioDumpParser.parseAudioPolicy(policy13)
        val byId = dump.sessions.associateBy { it.sessionId }
        assertEquals(setOf(12345, 12409, 12500), byId.keys)

        val yt = byId.getValue(12345)
        assertEquals(10200, yt.uid)
        assertTrue(yt.isCapturableUsage)
        assertFalse(yt.blocksCapture)
        assertEquals(true, yt.active)

        assertFalse(byId.getValue(12409).isCapturableUsage)
        assertTrue(byId.getValue(12500).blocksCapture)

        assertEquals(true, dump.captureAllowedByUid[10200])
        assertEquals(false, dump.captureAllowedByUid[10350])
    }

    @Test
    fun parsesRealAndroid15PolicyDump() {
        val dump = AudioDumpParser.parseAudioPolicy(policy15Real)
        val byId = dump.sessions.associateBy { it.sessionId }
        // Playback clients only (the REMOTE_SUBMIX recorder is dropped), duplicates merged.
        assertEquals(setOf(97, 113, 121), byId.keys)
        val player = byId.getValue(121)
        assertEquals(10208, player.uid)
        assertTrue(player.isCapturableUsage)
        assertFalse(player.blocksCapture)
        assertEquals(true, player.active)
        assertFalse(byId.getValue(97).isCapturableUsage)
        assertEquals(true, dump.captureAllowedByUid[10208])
        assertEquals(true, dump.captureAllowedByUid[1000])
    }

    @Test
    fun parsesAndroid10PolicyDump() {
        val dump = AudioDumpParser.parseAudioPolicy(policy10)
        val byId = dump.sessions.associateBy { it.sessionId }
        assertEquals(setOf(993, 1001), byId.keys)
        assertEquals(10123, byId.getValue(993).uid)
        assertEquals(true, byId.getValue(993).active)
        assertEquals(false, byId.getValue(1001).active)
        assertTrue(byId.getValue(1001).isCapturableUsage)
    }

    @Test
    fun parsesAudioServiceDump() {
        val dump = AudioDumpParser.parseAudioService(audioService)
        val byId = dump.sessions.associateBy { it.sessionId }
        assertEquals(setOf(12345, 0, 12701), byId.keys)
        assertEquals(10200, byId.getValue(12345).uid)
        assertEquals(true, byId.getValue(12345).active)
        assertEquals(false, byId.getValue(12701).active)
        assertTrue(byId.getValue(12701).blocksCapture)
        assertFalse(byId.getValue(0).isCapturableUsage)
        assertNull(dump.captureAllowedByUid[10200])
    }

    @Test
    fun emptyOrGarbageDumpsYieldNothing() {
        assertTrue(AudioDumpParser.parseAudioPolicy("").sessions.isEmpty())
        assertTrue(AudioDumpParser.parseAudioPolicy("Session ID: abc; uid x").sessions.isEmpty())
        assertTrue(AudioDumpParser.parseAudioService("nothing here").sessions.isEmpty())
    }
}
