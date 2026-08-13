import {
  PrismaClient,
  FeatureStatus,
  IntegrationCategory,
} from "@prisma/client";
const prisma = new PrismaClient();

async function main() {
  const adminPhone = process.env.SEED_ADMIN_PHONE ?? "09000000000";
  await prisma.user.upsert({
    where: { phone: adminPhone },
    update: { accountType: "SUPERADMIN", status: "ACTIVE" },
    create: {
      phone: adminPhone,
      accountType: "SUPERADMIN",
      status: "ACTIVE",
      phoneVerifiedAt: new Date(),
      profile: { create: { displayName: "مدیر سیستم" } },
    },
  });
  const plumbing = await prisma.businessType.upsert({
    where: { key: "plumber" },
    update: { enabled: true },
    create: {
      key: "plumber",
      nameFa: "لوله‌کش و تأسیسات",
      nameEn: "Plumbing",
      iconKey: "wrench-pipe",
    },
  });
  const featureKeys = [
    ["invoices", "صورتحساب"],
    ["inventory", "انبار"],
    ["reviews", "نظرات"],
    ["wallet", "کیف پول"],
    ["coins", "باشگاه و امتیاز"],
    ["sms", "پیامک"],
    ["verification", "نشان تأیید"],
    ["staff", "پرسنل"],
    ["online_payment", "پرداخت آنلاین"],
    ["business_discovery", "جستجوی کسب‌وکار"],
  ] as const;
  for (const [key, nameFa] of featureKeys) {
    await prisma.feature.upsert({
      where: { key },
      update: {},
      create: { key, nameFa, status: FeatureStatus.ENABLED },
    });
  }
  const free = await prisma.plan.upsert({
    where: { key: "free" },
    update: {},
    create: { key: "free", nameFa: "رایگان", priceRial: 0n },
  });
  const pro = await prisma.plan.upsert({
    where: { key: "pro" },
    update: {},
    create: { key: "pro", nameFa: "حرفه‌ای", priceRial: 5_000_000n },
  });
  const limits = [
    [free.id, "invoices", "monthly_invoices", 30n],
    [free.id, "inventory", "inventory_items", 100n],
    [free.id, "staff", "staff_accounts", 1n],
    [free.id, "sms", "monthly_sms", 100n],
    [pro.id, "invoices", "monthly_invoices", 500n],
    [pro.id, "inventory", "inventory_items", 5000n],
    [pro.id, "staff", "staff_accounts", 10n],
    [pro.id, "sms", "monthly_sms", 5000n],
  ] as const;
  for (const [planId, featureKey, limitKey, limitValue] of limits) {
    const feature = await prisma.feature.findUniqueOrThrow({
      where: { key: featureKey },
    });
    await prisma.planLimit.upsert({
      where: {
        planId_featureId_limitKey: { planId, featureId: feature.id, limitKey },
      },
      update: { limitValue, enabled: true },
      create: {
        planId,
        featureId: feature.id,
        limitKey,
        limitValue,
        enabled: true,
      },
    });
  }
  await prisma.loyaltyLevel.upsert({
    where: { key: "starter" },
    update: {},
    create: {
      key: "starter",
      nameFa: "شروع",
      minLifetimeCoins: 0,
      sortOrder: 0,
    },
  });
  await prisma.loyaltyLevel.upsert({
    where: { key: "active" },
    update: {},
    create: {
      key: "active",
      nameFa: "فعال",
      minLifetimeCoins: 500,
      sortOrder: 10,
    },
  });
  await prisma.loyaltyLevel.upsert({
    where: { key: "pro" },
    update: {},
    create: {
      key: "pro",
      nameFa: "همراه حرفه‌ای",
      minLifetimeCoins: 2500,
      autoClaimEnabled: true,
      sortOrder: 20,
    },
  });
  await prisma.coinRule.upsert({
    where: { key: "wallet_charge" },
    update: {},
    create: {
      key: "wallet_charge",
      nameFa: "شارژ کیف پول",
      sourceType: "WALLET_CHARGE",
      amountPerRial: "0.00002",
      minAmountRial: 100000n,
      claimRequired: true,
    },
  });
  await prisma.smsTemplate.upsert({
    where: { key: "invoice_ready" },
    update: {},
    create: {
      key: "invoice_ready",
      nameFa: "صورتحساب آماده است",
      kind: "INVOICE",
      body: "صورتحساب شما از {businessName} آماده است. برای مشاهده وارد اپلیکیشن کاربان شوید.",
      variables: ["businessName"],
      ownerEditable: true,
    },
  });
  await prisma.smsTemplate.upsert({
    where: { key: "install_invite" },
    update: {},
    create: {
      key: "install_invite",
      nameFa: "دعوت نصب اپ",
      kind: "INVITE",
      body: "{businessName} می‌خواهد برای شما صورتحساب صادر کند. اپلیکیشن کاربان را نصب و با همین شماره ثبت‌نام کنید.",
      variables: ["businessName"],
      ownerEditable: true,
    },
  });
  console.log({ plumbing: plumbing.id, plans: [free.id, pro.id] });
}
main().finally(() => prisma.$disconnect());
