const enamadHtml = `<a referrerpolicy='origin' target='_blank' href='https://trustseal.enamad.ir/?id=707242&Code=EHBQU8BMbloXnxweqJxwbHPnH1yLJ33i'><img referrerpolicy='origin' src='https://trustseal.enamad.ir/logo.aspx?id=707242&Code=EHBQU8BMbloXnxweqJxwbHPnH1yLJ33i' alt='' style='cursor:pointer' code='EHBQU8BMbloXnxweqJxwbHPnH1yLJ33i'></a>`;
export function EnamadSeal() {
  return (
    <div
      className="enamadSeal"
      aria-label="نماد اعتماد الکترونیکی"
      dangerouslySetInnerHTML={{ __html: enamadHtml }}
    />
  );
}
