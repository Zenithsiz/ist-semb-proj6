#import "util.typ": course, title, authors

#align(center)[
  #image("images/tecnico-logo.png", width: 70%)
  #v(4em)
]

#align(center)[
  #block(text(weight: 600, 2em, course))
  #v(8em, weak: true)

  #block(text(weight: 600, 1.75em, title))
  #v(3em, weak: true)

  #pad(
    top: 0.5em,
    bottom: 0.5em,
    x: 2em,
    grid(
      columns: (1fr,) * calc.min(1, authors.len()),
      gutter: 1em,
      ..authors.map(author => text(weight: 600, author)),
    ),
  )
]
