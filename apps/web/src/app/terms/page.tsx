import { SiteFrame } from "@/components/brand/site-frame";

export const metadata = {
  title: "Terms",
  description: "MATH SI is educational practice. Accounts are for the learner.",
};

export default function TermsPage() {
  return (
    <SiteFrame>
      <main className="mx-auto flex max-w-2xl flex-col gap-4 px-6 py-16">
        <h1 className="text-4xl">Terms</h1>
        <p>MATH SI is educational practice. An account is for the learner who creates it.</p>
        <p>The lessons and the Pip character belong to MATH SI.</p>
        <p>Do not abuse the API.</p>
      </main>
    </SiteFrame>
  );
}
