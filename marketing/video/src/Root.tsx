import { Composition } from "remotion";
import { Conversation, mainSeconds } from "./Conversation";
import { Reel } from "./Reel";
import { Edit, FPS, OUTRO_SECONDS } from "./types";
import sample from "../edits/es01.json";

const duration = ({ props }: { props: Edit }) => ({
  durationInFrames: Math.ceil((mainSeconds(props) + OUTRO_SECONDS) * FPS),
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
    calculateMetadata={duration}
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
  </>
);
