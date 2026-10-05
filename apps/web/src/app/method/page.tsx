export const metadata = {
  title: "Method",
  description: "A mission, specific feedback, and old ideas that come back just before they fade.",
};

export default function MethodPage() {
  return (
    <main className="mx-auto flex max-w-2xl flex-col gap-6 px-6 py-16">
      <h1 className="text-4xl">How a mission works</h1>
      <p>You open one short mission. Each screen asks for one move: a tap, a slider, or an arrow.</p>
      <p>A wrong answer names the mistake. You try a twin of the same idea, then you move on.</p>
      <p>Old ideas come back just before they fade, so yesterday’s arrow is still there tomorrow.</p>
      <p>A three-minute placement drops you where the pictures start to make sense.</p>
    </main>
  );
}
