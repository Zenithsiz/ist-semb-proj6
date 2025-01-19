#import "@preview/codly:1.2.0" as codly:
#import "util.typ" as util: code_figure, src_link


#set document(
	author: "Filipe Rodrigues",
	title: util.title,
	date: none
)
#set page(
	header: context {
		if counter(page).get().first() > 1 {
			image("images/tecnico-logo.png", height: 30pt)
		}
	},
	footer: context {
		if counter(page).get().first() > 1 {
			align(center, counter(page).display())
		}
	},
	margin: (x: 2cm, y: 30pt + 1.5cm)
)
#set text(
	font: "Libertinus Serif",
	lang: "en",
)
#set par(
	justify: true,
	leading: 0.65em,
)
#show link: underline

#show: codly.codly-init.with()

#include "cover.typ"
#pagebreak()

= Setup

For the setup, we hooked up an oscilloscope to the output of the pin we've chosen for the PWM output, which is GPIO 2 in our case.

= Experiment

#let main_src = read("src/main/main.c")

We'll be using the `ledc` module of esp32 for these experiments @ledc-docs.
This module implements support for pulse-width modulation (`PWM`), despite the name.
This is because `ledc` stands for "LED Control", and `PWM` circuits are typically used to control LED brightness.

In terms of configuration, the following `pwm_init` function configures the `PWM` for us, shown in @pwm-init

#codly.codly(range: (50, 70))
#code_figure(
	raw(main_src, lang: "c", block: true),
	caption: [PWM Setup]
) <pwm-init>

In particular, we have to setup 2 particular things. The `ledc` timer and channel.

In particular, the former defines all of the aspects that affect the wave, such as:

- Speed mode (`.speed_mode`): Low speed (`LEDC_LOW_SPEED_MODE`) implies that glitches may happen when live-swapping configurations, while high speed (`LEDC_HIGH_SPEED_MODE`) removes these glitches, but may not be available on many systems.

- Timer number (`.timer_num`): Determines which timer is used for keeping track of the PWM position.

- Duty resolution (`.duty_resolution`): Determines the number of bits (resolution) for the timer. Typically available from 1 to 14 bits, but higher bit counts are available on some systems.

- Frequency (`.freq_hz`): Determines the frequency of each pwm cycle.

- Clock config (`.clk_cfg`): Legacy configuration for the driver, one should always use `LEDC_AUTO_CLK`.

The latter shared some configuration with the previous, such as the speed mode and timer number, but also has other configuration, such as:

- Channel (`.channel`): Which `ledc` channel to use.

- Interrupt (`.intr_type`): Interrupt support.

- GPIO number (`.gpio_num`): Which GPIO to use for the output.

- Duty (`.duty`): The starting duty cycle, from 0 to $2^"duty_resolution"$, non inclusive.

- High point (`.hpoint`): At which point during the duty cycle to go high, with the same range as `duty`.

== Test 1

For this test, we ran the following `test1` function:

#codly.codly(
	ranges: ((72, 75), (113, 113), (116, 116)),
	smart-skip: (first: false, last: false, rest: true),
	highlights: (
		(line: 116, start: 3, end: 4, fill: red),
	),
)
#code_figure(
	raw(main_src, lang: "c", block: true),
	caption: [Test 1 code]
) <test1-code>

This function sets the duty cycle to $4095 / (2^13 - 1) ≈ 50%$

We saw the following output on the oscilloscope, shown in @test1-output:

#figure(
	image("images/test1.jpg", width: 50%),
	caption: [Test 1 output]
) <test1-output>

As expected, we see a square wave, with an peak-to-peak amplitude of $3.48 V$, a frequency of $5 "kHz"$, and duty cycle of $"pos width" / "period" = (100.0 "µs") / (200.0 "µs") = 50%$.

== Test 2

For this test, we adjusted the frequency from $5 "kHz"$ to $6 "kHz"$, shown by the changes in @test2-code

#codly.codly(
	range: (55, 55),
	highlights: (
		(line: 55, start: 16, end: 19, fill: red, tag: [
			#show: body => box(fill: color.green.lighten(80%), outset: 100em, body)
			#set text(fill: green.darken(50%))
			6000
		]),
	),
)
#code_figure(
	raw(main_src, lang: "c", block: true),
	caption: "Test 2 code"
) <test2-code>

We saw the following output on the oscilloscope, shown in @test2-output:

#figure(
	image("images/test2.jpg", width: 50%),
	caption: [Test 2 output]
) <test2-output>

As expected, we see a similar square wave to test 1, but with a frequency of $6 "kHz"$. The duty cycle remains $"pos width" / "period" = (83.38 "µs") / (166.8 "µs") ≈ 50%$.

== Test 3

For this test, we ran the following `test3` function, shown in @test3-code:

#[
	#show figure: set block(breakable: true)
	#codly.codly(
		ranges: ((87, 111), (113, 113), (117, 117)),
		smart-skip: (first: false, last: false, rest: true),
		highlights: (
			(line: 117, start: 3, end: 4, fill: red),
		),
	)
	#code_figure(
		raw(main_src, lang: "c", block: true),
		caption: [Test 3 code]
	) <test3-code>
]

We recorded a video of the output. Unfortunately, we cannot embed it into the paper, but we provide a link below to it, available on this project's repository:

#link("https://github.com/Zenithsiz/ist-semb-proj6/blob/main/videos/test3.mp4")


As expected, we see a square wave, with a constant peak-to-peak amplitude of $3.48 V$, a frequency of $6 "kHz"$, and a changing duty cycle, ranging from $0%$ to $100%$.

= Discussion Questions

= How the hardware PWM works?

Hardware PWM works by setting up a hardware timer that toggles the output of the GPIO pin when it's set off.

= Why to do not implement in software?

Hardware timers can have much better precision than tracking the wave in software, and without needing to use up any CPU cycles.

= How does the frequency change affect the PWM waveform?

Changing the frequency changes the on and off time of the pwm wave by scaling them uniformly, in order to ensure the duty cycle stays the same.

= What is the maximum resolution of the PWM signal, and how is it affected by the frequency setting?

The typical maximum supported resolution of the PWM signal is 14 bits, but up to 20 bits if available on systems where `SOC_LEDC_TIMER_BIT_WIDTH > 14`.

= How accurately does the ESP32 produce the desired duty cycles?

For the resolutions and duty cycles we tested, we saw near perfect accuracy, but we expect that as the resolution increases, the waves will be less and less accurate.

= Why you need to configure the timer?

Because the system uses a timer to toggle the pin to implement the PWM.

= Which outputs can be configured as a PWM?

On our system, according it's datasheet @datasheet (§3.11, Table 10), any GPIO pins may be used for LED PWM.

= How many channels you have disponible in ESP32?

According to the source code, by default there are 5 channels, but if `SOC_LEDC_CHANNEL_NUM > 6`, then up to 7 channels are defined.

= How the difference between the LEDC mode and the MCPWM?

`MCPWM` mode is used for motor control, while `LEDC` is usually used to control LEDS.

The main difference is that `MCPWM` includes a Sync GPIO input to receive feedback from the motor, allowing it to stay in sync with it. The API for `MCPWM` control also allows for several callbacks that are called at specific points during a PWM cycle.

#bibliography("bibliography.yaml", style: "ieee", full: true)
