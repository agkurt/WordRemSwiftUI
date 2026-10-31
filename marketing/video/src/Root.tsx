import { Composition } from "remotion";
import { Conversation, mainSeconds } from "./Conversation";
import { Reel } from "./Reel";
import { GAP, Sheet, SheetProps } from "./Sheet";
import { Story, StoryFrame } from "./Story";
import { Bob, BOB_OUTRO, BobEdit, bobMain } from "./Bob";
import { SlideFrame, SlideProps } from "./Slides";
import { Explainer, ExplainerEdit } from "./Explainer";
import bob from "../edits/bob-ep01.json";
import { Edit, FPS, OUTRO_SECONDS, RECAP_SECONDS } from "./types";
import sample from "../edits/es01.json";

const duration = ({ props }: { props: Edit }) => ({
  durationInFrames: Math.ceil((mainSeconds(props) + OUTRO_SECONDS) * FPS),
});
const reelDuration = ({ props }: { props: Edit }) => ({
  durationInFrames: Math.ceil((mainSeconds(props) + RECAP_SECONDS + OUTRO_SECONDS) * FPS),
});

export const Root = () => (
  <>
  <Composition
    id="Reel"
    component={Reel}
    width={1080}
    height={1920}
    fps={FPS}
    durationInFrames={FPS * 10}
    defaultProps={sample as unknown as Edit}
    calculateMetadata={reelDuration}
  />
  <Composition
    id="Conversation"
    component={Conversation}
    width={1080}
    height={1920}
    fps={FPS}
    durationInFrames={FPS * 10}
    defaultProps={sample as unknown as Edit}
    calculateMetadata={duration}
  />
  <Composition
    id="Bob"
    component={Bob}
    width={1080}
    height={1920}
    fps={FPS}
    durationInFrames={FPS * 10}
    defaultProps={bob as unknown as BobEdit}
    calculateMetadata={({ props }: { props: BobEdit }) => ({ durationInFrames: Math.ceil((bobMain(props) + BOB_OUTRO) * FPS) })}
  />
  <Composition
    id="Explainer"
    component={Explainer}
    width={1080}
    height={1920}
    fps={FPS}
    durationInFrames={FPS * 10}
    defaultProps={{ kind: "explainer", id: "", hook: "", cta: "Coming soon on the App Store", total: 3,
      beats: [{ card: { kind: "hook", n: "4", title: "phrases that make you sound *rude*", sub: "in English 😬" }, from: 0, to: 3 }], sentences: [] } as ExplainerEdit}
    calculateMetadata={({ props }: { props: ExplainerEdit }) => ({ durationInFrames: Math.ceil(props.total * FPS) })}
  />
  <Composition
    id="Slide"
    component={SlideFrame}
    width={1080}
    height={1920}
    fps={FPS}
    durationInFrames={1}
    defaultProps={{ kind: "cover", title: "Stop saying these in *English* 🚫", sub: "say this instead ✅", index: 0, total: 7 } as SlideProps}
  />
  <Composition
    id="Story"
    component={Story}
    width={1080}
    height={1920}
    fps={FPS}
    durationInFrames={1}
    defaultProps={{ kind: "teach", label: "Günün kalıbı", phrase: "What's the *purpose* of your visit?", meaning: "Ziyaretinizin amacı nedir?" } as StoryFrame}
  />
  <Composition
    id="Sheet"
    component={Sheet}
    width={100}
    height={100}
    fps={FPS}
    durationInFrames={1}
    defaultProps={{ images: [], labels: [], cols: 1, w: 100, h: 100 } as SheetProps}
    calculateMetadata={({ props }: { props: SheetProps }) => ({
      width: props.cols * (props.w + GAP),
      height: Math.ceil(props.images.length / props.cols) * (props.h + GAP),
    })}
  />
  </>
);
