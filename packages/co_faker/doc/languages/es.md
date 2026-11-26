# Spanish (Spain) (`es`)

status: localized

español. The national locale is `es_ES`. Peninsular Spanish (`es_ES`).

The status line above is read by the tests of the package:

- `planned`: the language has no data yet. Its domain text bundle, clinic data,
  and SaaS data are empty stubs, and the language reads English.
- `localized`: all three are written. Change the line to `localized` in the same
  pull request that writes them: the tests compare it with the registries.

The domain text bundle, the clinic data, and the SaaS data were written for
co-package#71. **The translation is an AI draft that a native speaker has
not reviewed yet**: the checklist at the end lists what a reviewer
has to look at first. See
[README.md](README.md) for the work, the gate, and the format of this file.

## Glossary

One row for each term that the texts use for the same thing, in English. A term
has one translation, and it is the only one that the texts of the language
write; the forbidden forms are the spellings that must not appear anywhere in
them (another variant, an English loanword, a term of another region). The
rationale says why. Separate forbidden forms with `;`.

| Source term (English) | Translation | Forbidden forms | Rationale |
| --- | --- | --- | --- |
| Appointment | cita | turno médico; agendar | Peninsular Spanish books a `cita`; `turno` and `agendar` are Latin American. |
| Computer | ordenador | computadora; computador | Peninsular word; the American forms read as another region. |
| Mobile phone | móvil | celular | Peninsular word for the phone. |
| Package (of sessions) | bono | paquete de sesiones | A clinic or gym sells a `bono` of sessions in Spain. |
| Card terminal | datáfono | TPV | The word a Spanish shop uses for the card reader; one term only. |
| Medical record | historia clínica | expediente médico; ficha clínica | The term of Spanish health law (Ley 41/2002). |
| Parking | aparcamiento | estacionamiento; parqueadero | Peninsular word. |
| Rent | alquiler | rentar; renta mensual | `renta` is income in Spain; renting is `alquilar`. |
| Juice | zumo | jugo | Peninsular word. |

## Format conventions

One line for each topic: how the language writes it, with an example.

| Topic | Convention |
| --- | --- |
| Currency and amounts (`1.234,00 €`) | `CoCurrencyFormat(code: 'EUR', symbol: '€', pattern: '{amount}\u00A0{symbol}', groupSeparator: '.', decimalSeparator: ',', fractionDigits: 2)`; the price scale of the French data. SaaS adds 21 % IVA. |
| Dates and times | `dd/mm/aaaa`, a weekday in lower case (`miércoles 25/11`), ranges `del {from} al {to}`, the 24-hour clock (`de 18:00 a 20:00`). |
| Numbers: separators and units | A no-break space (`\u00A0` in the source) between a number and its unit and before `%` (`2\u00A0ml`, `80\u00A0%`); `1000` without a separator in prose. |
| Punctuation and quotation marks (`¿…?`, `¡…!`, `«…»`) | Opening `¿` and `¡` before every question and exclamation; coined names in `«»`. |
| Register: `usted` or `tú` | `usted` in every patient and customer text (`Por favor, confirme…`). |
| Gender and plural in a template that a value fills | A value follows a colon or `nivel`, so no article or `del`/`al` contraction agrees with it; persons as `Tutor/a de {name1}`. |
| Peninsular spelling and vocabulary (not Latin American) | `ordenador`, `móvil`, `zumo`, `aparcamiento`, `cita`; the glossary forbids the American forms. |

## Native-speaker review checklist

Fill in what a reviewer has to look at: the terms that are medical, legal, or
financial, the register of a patient notice, the templates that a value fills,
and every text that the author is not sure about.

- [ ] The glossary terms read as a native speaker of the language writes them.
- [ ] The register is the same in every patient and customer text.
- [ ] Amounts, dates, and numbers follow the conventions above.
- [ ] A template stays grammatical with every value that fills it.
- [ ] Medical: the ICD-10 names (Acné vulgar, Cloasma, Verrugas víricas, Dermatitis atópica, Rosácea no especificada), `Técnico en cuidados de enfermería`, `Director médico`, `máculas parduzcas`, `regiones malares`, `tercio inferior facial`, `fotoprotección`, `febrícula`, `glucemia posprandial`, the vital-sign abbreviations `TA` / `FC` / `T.ª`, `Revisión del uso de medicamentos` (DUR).
- [ ] Veterinary and dental: `preventivo contra la filariosis`, `Vacuna polivalente`, `Vacunación antirrábica`, `endodoncia`, `obturación con resina`, `planificación de corona`, `Circonio`, `Resina compuesta`, `Limpieza dental`.
- [ ] Care: `Grado de cuidados 1–5` and `Grado de apoyo cognitivo` translate Korean care grades; Spain's dependency system uses Grado I–III.
- [ ] Legal and financial: `Consentimiento informado`, `tratamiento de datos personales`, `Cesión a terceros`, the disclaimer sentence, `Tutor legal`, `Baja voluntaria`, both `Información general:` texts, `Especialista fiscal/jurídico/laboral ficticio`, `diferencial` (FX spread), `Banco colaborador`, `Sistema público de salud` for `nhis`, `Solicitud de reembolso`, `Cobro automático`, `Pago vencido`, the `B########` tax-ID shape, the `***####**` DNI mask, `Maestro` as the fourth card network.
- [ ] Word choices: `Bono`, `Datáfono`, `[Publi]`, `Profe {name1}`, `Empanadillas caseras` (dumplings), `Solomillo de pollo`, `Bebidas a escote`, `Quedada`, `Pódcast`, `Wifi`, `Enrutador`, `Mínimo privilegio`, `Función hash`, `Temporada media` (regular season), `Carga para transporte troncal`, `Suplemento por plataforma elevadora`.
- [ ] Invented names are not real places or brands: Luzaral, Riberazul, Jaramar, Campoalba, Solarroyo, Pinar Alto, Mutua Brisanorte, Vida Altavista, the drug stems Velquira, Tormaxen, Brisolan, and the creators `Jardín de Arena Lenta` and `Veta de Cielo`.
