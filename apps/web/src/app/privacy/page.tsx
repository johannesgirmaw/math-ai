export const metadata = {
  title: "Privacy",
  description: "What Axiom stores, and the contact for privacy questions.",
};

export default function PrivacyPage() {
  return (
    <main className="mx-auto flex max-w-2xl flex-col gap-4 px-6 py-16">
      <h1 className="text-4xl">Privacy</h1>
      <p>Axiom stores your email, password hash, display name, timezone, daily goal, and lesson results so your path can continue on another day.</p>
      <p>Product analytics, when configured, receive lesson events without your email address.</p>
      <p>Axiom does not sell personal data.</p>
      <p>Contact privacy@axiom.app.</p>
    </main>
  );
}
