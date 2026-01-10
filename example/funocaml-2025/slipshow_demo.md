---
dimension: 16:9
---

<style>
#nuage-de-points.stop p {
  transition: opacity 1s, transform 1s;
  opacity: 0.1;
}
#nuage-de-points.stop.all-stop p {
  opacity: 1;
}
#nuage-de-points.stop #cmfiles.selected {
  transform: scale(2) translateX(50px);
}
#nuage-de-points.stop #not-bs.selected {
  transform: scale(2) translateX(-50px);
}
#nuage-de-points.stop #nbosbst.selected {
  transform: scale(2) translateX(150px) translateY(50px);
}
#nuage-de-points.stop #custom_script2.selected {
  transform: scale(2) translateX(-350px) translateY(-150px);
}
#nuage-de-points.stop #video.selected {
  transform: scale(2) translateX(150px) translateY(-100px);
}
#nuage-de-points.stop #embedded-pdfs.selected {
  transform: scale(2) translateX(-25px);
}
#nuage-de-points.stop #markdown-output.selected {
  transform: scale(2) translateX(-125px) translateY(25px);
}
#nuage-de-points.stop #hot-reloading.selected {
  transform: scale(2) translateX(125px);
}
#nuage-de-points.stop #available-vscode.selected {
  transform: scale(2) translateX(-125px);
}
#nuage-de-points.stop #live-collab.selected {
  transform: scale(2) translateX(225px);
}
#nuage-de-points.stop #user-def-dim.selected {
  transform: scale(2) translateY(100px);
}
#nuage-de-points.stop #ext-doc-tut.selected {
  transform: scale(2) translateX(-150px);
}
#nuage-de-points.stop #hierar-pres.selected {
  transform: scale(2) translateX(300px);
}
#nuage-de-points.stop #satheorem.selected {
  transform: scale(2) translateX(-200px) translateY(100px);
}
#nuage-de-points.stop #offline-first.selected {
  transform: scale(2) translateX(-200px) translateY(100px);
}
#nuage-de-points.stop #versionning-friendly.selected {
  transform: scale(2) translateX(-200px) translateY(-100px);
}
#nuage-de-points.stop #friendly-community.selected {
  transform: scale(2) translateX(200px) translateY(-100px);
}
#nuage-de-points.stop #secure-by-design.selected {
  transform: scale(2) translateX(-200px) translateY(-100px);
}
#nuage-de-points.stop #no-llms.selected {
  transform: scale(2) translateX(200px) translateY(100px);
}
#nuage-de-points.stop #feature-toc.selected {
  transform: scale(2) translateX(-200px);
}
#nuage-de-points.stop .selected {
  opacity: 1;
  transform: scale(2);
}
#nuage-de-points.stop .finished {
  transform: scale(1);
  opacity: 0;
}
#nuage-de-points {
  display: flex;
  flex-wrap: wrap;
  gap: 0px;
  column-gap: 157px;
  font-size: 1.2em;
  justify-content: space-around;
}
#nuage-de-points p {
  margin-top: 20px;
  margin-bottom: 20px;
}
.abs {
  position: absolute;
}
#no-llms {
  top: 90px;
  left: 30px;
}
#compat-pointer {
  top: 590px;
  left: 530px;
  transform: rotate(40deg);
}
#can-make-coffee {
  top: 350px;
  left: 930px;
}
#nlnet-sponsored {
  top: 280px;
  left: 990px;
  transform: rotate(-10deg);
}
#type-safe {
  top: 230px;
  left: 390px;
  transform: rotate(-180deg);
}
#live-collab {
  top: 430px;
  left: -150px;
  transform: rotate(90deg);
}
#syntax-high {
  top: 530px;
  left: 870px;
  transform: rotate(-30deg);
}
#offline-first {
  top: 30px;
  left: 1670px;
  transform: rotate(-10deg);
}
#satheorem {
  top: 650px;
  left: 1170px;
  transform:  translateX(350px) rotate(-90deg);
}
#adaptative-scaling {
  top: 880px;
  left: 570px;
  transform:  translateX(350px) rotate(-55deg);
}
#user-def-dim {
  top: 90px;
  left: 570px;
}
#math_support {
  top: 180px;
  left: 1200px;
  transform: rotate(35deg);
}
#frame.stop {
  opacity: 1;
}
#frame {
  transition: opacity 3s;
  transition-delay: 2s;
  opacity: 0;
  position: absolute;
  top: 370px;
  left: 50px;
  width: 600px;
  height: 400px;
//  background-color: rgba(255,0,0,0.5);
  overflow: visible;
}
#rec1 {
  transform:  translate(-350px, -150px) scale(0.4);
}
</style>

# Slipshow: A *full-featured* presentation tool

{#nuage-de-points children:pause}
---

{#cmfiles}
Compile markdown files

{#gen-stand}
Generate *Standalone* HTML files

{#not-bs}
Not based on slides

{#can-zoom}
Can Zoom

{#can-annotate}
You can annotate your presentation

{#custom_script}
Custom scripts

{#hot-reloading}
Write your presentation with hot-reloading

{#embedded-pdfs}
Support for embedding PDFs

{#video}
Embed Videos and Audio

{#available-static}
Available as a static binary

{#available-vscode}
Available as a VSCode extension

{#available-gui}
Available with a GUI

{#bidirectional}
Bi-directional

{#feature-toc}
Features a table of content

{#feature-theme}
Has supports for themes

{#custom_script2}
Allow the execution of custom scripts

{#nbosbst}
Not based on slides (but supports them)

{#extensible-js}
Extensible via JavaScript

{#markdown-output}
Markdown output

{#has-speaker-view}
Speaker view

{#front-support}
Frontmatter support

{#mobile-support}
Mobile support

{#multi-input}
Multi-file input

{#hierar-pres}
Hierarchical presentation

{#many-predefined-actions}
Many predefined actions

{#ext-doc-tut}
Extensive documentation and tutorial

{#friendly-community}
Friendly community (me)

{#ext-help-page}
Extensive help page

{#open-source}
Open source

{#secure-by-design}
Secure-by-design

{#lightning-fast}
Lightning fast

{#has-nice-logo}
Has a nice logo

{#fun-name}
Fun name

{#versionning-friendly}
Versionning-friendly

{.abs #no-llms}
No LLM knows about it

{.abs #compat-pointer}
Compatible with pointer devices

{.abs #can-make-coffee}
Can make coffee

{.abs #nlnet-sponsored}
Sponsored by NLNet

{.abs #type-safe}
Type safe

{.abs #live-collab}
Live-collaboration editing

{.abs #syntax-high}
Syntax highlighting

{.abs #offline-first}
Offline first

{.abs #satheorem}
Support for environment such as `theorem`

{.abs #adaptative-scaling}
Adaptative scaling

{.abs #user-def-dim}
User-defined dimensions

{.abs #math_support speaker-note=sn-stop}
Mathematics support

---

