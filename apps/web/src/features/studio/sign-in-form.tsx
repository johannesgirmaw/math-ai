"use client";

import { useState, type FormEvent } from "react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

export function SignInForm({ nextPath }: { nextPath: string }) {
  const router = useRouter();
  const [mode, setMode] = useState<"in" | "up">("in");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [name, setName] = useState("");
  const [emailError, setEmailError] = useState("");
  const [passwordError, setPasswordError] = useState("");
  const [formError, setFormError] = useState("");
  const [busy, setBusy] = useState(false);

  async function submit(event: FormEvent) {
    event.preventDefault();
    if (!email.includes("@")) {
      setEmailError("Enter your email.");
      setPasswordError("");
      return;
    }
    if (password.length < 8) {
      setEmailError("");
      setPasswordError("Use at least 8 characters.");
      return;
    }
    setBusy(true);
    setEmailError("");
    setPasswordError("");
    setFormError("");
    const path = mode === "up" ? "/api/v1/auth/sign-up/email" : "/api/v1/auth/sign-in/email";
    const response = await fetch(path, {
      method: "POST",
      headers: { "content-type": "application/json" },
      credentials: "include",
      body: JSON.stringify(mode === "up" ? { email, password, name: name || email } : { email, password }),
    });
    setBusy(false);
    if (!response.ok) {
      setFormError(mode === "up" ? "Could not create that account." : "That email or password did not match.");
      return;
    }
    router.push(nextPath);
    router.refresh();
  }

  return (
    <form onSubmit={submit} className="flex flex-col gap-4">
      {mode === "up" ? (
        <div className="flex flex-col gap-2">
          <Label htmlFor="name">Name</Label>
          <Input id="name" value={name} onChange={(event) => setName(event.target.value)} />
        </div>
      ) : null}
      <div className="flex flex-col gap-2">
        <Label htmlFor="email">Email</Label>
        <Input id="email" type="email" value={email} onChange={(event) => setEmail(event.target.value)} />
        {emailError ? <p className="text-sm text-destructive">{emailError}</p> : null}
      </div>
      <div className="flex flex-col gap-2">
        <Label htmlFor="password">Password</Label>
        <Input
          id="password"
          type="password"
          value={password}
          onChange={(event) => setPassword(event.target.value)}
        />
        {passwordError ? <p className="text-sm text-destructive">{passwordError}</p> : null}
      </div>
      {formError ? <p className="text-sm text-destructive">{formError}</p> : null}
      <Button type="submit" disabled={busy}>
        {busy ? "Working" : mode === "up" ? "Create account" : "Sign in"}
      </Button>
      <button
        type="button"
        className="text-left text-sm underline"
        onClick={() => setMode(mode === "up" ? "in" : "up")}
      >
        {mode === "up" ? "Already have an account" : "Create an account"}
      </button>
    </form>
  );
}
