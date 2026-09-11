/**
 * What each editable document is allowed to contain, described once.
 *
 * The panel this replaced read a document's existing keys and drew an input
 * beside each one. That works until the owner wants a field the document does
 * not already have -- a second stat, a link, a screenshot on an app that has
 * never had one -- at which point there is nothing to clone and no way to add
 * it. It also cannot tell a URL from a caption, so it cannot validate either.
 *
 * This file is the missing half. It is plain data, not code, for three
 * reasons: the Worker imports it to validate a publish, the panel is handed it
 * as JSON to draw the editor, and Codex can read it as the written contract
 * for what the public app is being asked to consume. One description, three
 * consumers, no second copy to keep in step.
 *
 * It is derived from the Freezed models under `lib/content/models/`, which are
 * what the public app actually parses today. Where the two disagree the model
 * wins and this file is wrong: `worker/test/content-schema.test.js` checks
 * every bundled document against it, so that disagreement fails a test rather
 * than reaching a publish.
 *
 * Adding a field here does **not** make it appear on the site. It makes it
 * editable and storable. The public consumer is Codex's work, and until it
 * exists the field is marked `consumer: 'pending'` and the editor says so
 * rather than implying the site will show it. See `20-APP-ADMIN-CONTRACT.md`.
 */

/// ISO 3166-1 alpha-2, as used by `profile.reach` and `app.country`.
export const countryPattern = /^[A-Z]{2}$/;

/// Year and month. The content uses month precision throughout, because that
/// is the precision the owner's records actually have.
export const monthPattern = /^\d{4}-(0[1-9]|1[0-2])$/;

/// A slug used as a stable identifier and, for apps, as part of a public URL.
export const idPattern = /^[a-z0-9]+(-[a-z0-9]+)*$/;

/// A reference to stored media, or a path into the app's bundled assets.
///
/// Both are accepted because both are in the bundled documents today: the
/// portrait and the coursework images are bundle paths, and anything uploaded
/// through the panel is a content-addressed `/v1/media/` id.
export const assetPattern = /^(\/v1\/media\/[0-9a-f]{32}|assets\/[\w./-]+)$/;

/// Where the work has been. Not a general list: these are the codes the
/// content uses, and a code the app has no flag for renders as nothing.
export const knownCountries = [
  'AM', 'CA', 'DE', 'EG', 'GB', 'QA', 'RU', 'SA', 'AE', 'US', 'FR', 'NL',
];

const localised = (key, label, options = {}) => {
  const {long = false, ...rest} = options;
  return {
    key,
    kind: long ? 'localizedParagraph' : 'localized',
    label,
    ...rest,
  };
};

/// The five documents, in the order the panel lists them.
///
/// `section` is what the owner sees in the navigation. The file name is an
/// implementation detail he should not have to think about, which is why it
/// is not the label.
export const documents = [
  {
    file: 'profile.json',
    section: 'Profile',
    blurb: 'Your name, how the site introduces you, your links and the figures on the home page.',
    warning: null,
    fields: [
      localised('name', 'Full name', {
        required: true,
        help: 'The legal name. Used by the CV and by search-engine metadata.',
      }),
      localised('displayName', 'Preferred name', {
        help: 'What visitors are shown. Falls back to the full name when empty.',
      }),
      localised('greeting', 'Greeting', {
        help: 'The first line of the home page, before the name.',
      }),
      localised('positioning', 'One-line introduction', {
        required: true,
        long: true,
      }),
      localised('biography', 'Biography', {
        long: true,
        help: 'The longer answer, shown on About.',
      }),
      localised('location', 'Where you are'),
      localised('status', 'Current status'),
      {
        key: 'venture',
        kind: 'object',
        label: 'Venture',
        help: 'A company you co-founded. Leave empty if there is none to claim.',
        fields: [
          localised('label', 'Description', {required: true}),
          {key: 'url', kind: 'url', label: 'Website', nullable: true},
        ],
      },
      {
        key: 'contact',
        kind: 'object',
        label: 'Contact',
        required: true,
        fields: [
          {key: 'email', kind: 'email', label: 'Email', required: true},
          {key: 'phone', kind: 'tel', label: 'Phone', nullable: true},
          {key: 'linkedin', kind: 'url', label: 'LinkedIn', nullable: true},
          {key: 'github', kind: 'url', label: 'GitHub', nullable: true},
          {key: 'gitlab', kind: 'url', label: 'GitLab', nullable: true},
          {key: 'medium', kind: 'url', label: 'Medium', nullable: true},
          {key: 'linktree', kind: 'url', label: 'Linktree', nullable: true},
          {key: 'calendly', kind: 'url', label: 'Calendly', nullable: true},
        ],
      },
      {
        key: 'cvFile',
        kind: 'asset',
        media: 'document',
        label: 'CV file',
        help: 'A path into the app bundle. Uploading a PDF here is not supported yet.',
        consumer: 'live',
        uploadable: false,
      },
      {
        key: 'portrait',
        kind: 'object',
        label: 'Portrait',
        fields: [
          {
            key: 'src',
            kind: 'asset',
            media: 'image',
            label: 'Photograph',
            required: true,
          },
          {
            key: 'isPlaceholder',
            kind: 'boolean',
            label: 'This is a placeholder, not a real photograph',
            required: true,
          },
        ],
      },
      {
        key: 'stats',
        kind: 'list',
        label: 'Figures',
        addLabel: 'Add a figure',
        help: 'Shown on the home page. Every one of these is a claim about you and needs a source when it changes.',
        of: {
          kind: 'object',
          expand: 'inline',
          titleFrom: 'value',
          subtitleFrom: 'label',
          fields: [
            {
              key: 'value',
              kind: 'text',
              label: 'Figure',
              required: true,
              claim: true,
              help: 'Written as it should read: "5+", "MSc", "25".',
            },
            localised('label', 'What it counts', {required: true}),
          ],
        },
      },
      {
        key: 'reach',
        kind: 'list',
        label: 'Countries the work has reached',
        addLabel: 'Add a country',
        help: 'Two-letter codes. Includes places a client was, not only places you sat.',
        of: {kind: 'country', label: 'Country'},
      },
    ],
  },
  {
    file: 'apps.json',
    section: 'Work',
    blurb: 'The applications listed on the Work page.',
    warning: null,
    listKey: 'apps',
    fields: [
      {
        key: 'apps',
        kind: 'list',
        label: 'Applications',
        addLabel: 'Add an application',
        of: {
          kind: 'object',
          titleFrom: 'name',
          subtitleFrom: 'role',
          fields: [
            {
              key: 'id',
              kind: 'id',
              label: 'Identifier',
              required: true,
              unique: true,
              help: 'Lower case, hyphenated. Used in the address of the project page, so changing it breaks any link already shared.',
            },
            {key: 'name', kind: 'text', label: 'Name', required: true},
            {
              key: 'platforms',
              kind: 'choiceList',
              label: 'Where it is published',
              required: true,
              options: [
                {value: 'ios', label: 'App Store'},
                {value: 'android', label: 'Google Play'},
                {value: 'pub', label: 'pub.dev'},
              ],
            },
            {
              key: 'store',
              kind: 'map',
              label: 'Store links',
              required: true,
              keys: [
                {value: 'ios', label: 'App Store'},
                {value: 'android', label: 'Google Play'},
                {value: 'pub', label: 'pub.dev'},
              ],
              of: {kind: 'url'},
              help: 'Leave a store empty when the app has no public listing. An empty link is better than a broken one.',
            },
            {
              key: 'domain',
              kind: 'choice',
              label: 'Domain',
              required: true,
              options: [
                'Travel', 'Mobility', 'Education', 'Retail', 'Services',
                'Marketplace', 'Consumer', 'Safety', 'Open source',
              ].map((value) => ({value, label: value})),
            },
            localised('role', 'What you did', {long: true}),
            {
              key: 'metric',
              kind: 'text',
              label: 'Headline result',
              claim: true,
              help: 'A figure a reader could ask you about. Needs a source when it changes.',
            },
            {key: 'country', kind: 'country', label: 'Country'},
            {
              key: 'engagement',
              kind: 'choice',
              label: 'How you were engaged',
              options: [
                {value: 'freelance', label: 'Freelance, direct with the client'},
                {value: 'contract', label: 'Fixed-term contract through a company'},
              ],
            },
            {
              key: 'screenshot',
              kind: 'asset',
              media: 'image',
              label: 'Screenshot',
              help: 'Shown on the Work card in place of the drawn panel.',
            },
            {
              key: 'featured',
              kind: 'boolean',
              label: 'Feature this on the home page',
            },
          ],
        },
      },
    ],
  },
  {
    file: 'career.json',
    section: 'Journey',
    blurb: 'The stops on the map and the timeline beneath it.',
    warning:
      'This is the work history a recruiter checks against your CV. Dates and employers here are claims about you.',
    listKey: 'roles',
    fields: [
      {
        key: 'roles',
        kind: 'list',
        label: 'Stops',
        addLabel: 'Add a stop',
        of: {
          kind: 'object',
          titleFrom: 'company',
          subtitleFrom: 'title',
          fields: [
            {
              key: 'id',
              kind: 'id',
              label: 'Identifier',
              required: true,
              unique: true,
            },
            {
              key: 'kind',
              kind: 'choice',
              label: 'Kind of stop',
              required: true,
              options: [
                {value: 'role', label: 'A job'},
                {value: 'study', label: 'A period of study'},
              ],
            },
            {key: 'company', kind: 'text', label: 'Employer or institution'},
            localised('title', 'Title'),
            localised('summary', 'What happened here', {long: true}),
            {key: 'country', kind: 'country', label: 'Country', required: true},
            {key: 'city', kind: 'text', label: 'City', required: true},
            {
              key: 'coords',
              kind: 'coords',
              label: 'Position on the map',
              required: true,
              help: 'Latitude then longitude, in degrees.',
            },
            {key: 'start', kind: 'month', label: 'Started', required: true},
            {
              key: 'end',
              kind: 'month',
              label: 'Ended',
              help: 'Leave empty while this is still current.',
            },
            {
              key: 'employment',
              kind: 'choice',
              label: 'Employment',
              options: [
                {value: 'full-time', label: 'Full time'},
                {
                  value: 'full-time then part-time',
                  label: 'Full time, then part time',
                },
              ],
            },
            {
              key: 'traceWeight',
              kind: 'number',
              label: 'Weight of the route line',
              min: 0,
              max: 1,
              help: 'How prominently the map draws the line into this stop. Presentation only, not a claim.',
            },
            {
              key: 'stack',
              kind: 'list',
              label: 'Technologies',
              addLabel: 'Add a technology',
              of: {kind: 'text'},
              consumer: 'withdrawn',
              help: 'The Journey page no longer draws these chips. Kept so the record is not lost.',
            },
            {
              key: 'appIds',
              kind: 'list',
              label: 'Applications built here',
              addLabel: 'Link an application',
              of: {kind: 'reference', references: 'apps.json'},
            },
          ],
        },
      },
    ],
  },
  {
    file: 'education.json',
    section: 'Education',
    blurb: 'Qualifications, module marks and the coursework behind them.',
    warning:
      'These are marks and qualifications. A number changed here is a claim, and publishing needs a source.',
    listKey: 'entries',
    fields: [
      {
        key: 'entries',
        kind: 'list',
        label: 'Qualifications',
        addLabel: 'Add a qualification',
        of: {
          kind: 'object',
          titleFrom: 'institution',
          subtitleFrom: 'award',
          fields: [
            localised('institution', 'Institution', {required: true}),
            localised('award', 'Award', {required: true}),
            {key: 'start', kind: 'month', label: 'Started', required: true},
            {key: 'end', kind: 'month', label: 'Ended', required: true},
            localised('status', 'Result'),
            {
              key: 'overallMark',
              kind: 'number',
              label: 'Overall mark',
              min: 0,
              max: 100,
              claim: true,
            },
            {
              key: 'modules',
              kind: 'list',
              label: 'Modules',
              addLabel: 'Add a module',
              of: {
                kind: 'object',
                titleFrom: 'name',
                subtitleFrom: 'mark',
                fields: [
                  localised('name', 'Module', {required: true}),
                  {
                    key: 'mark',
                    kind: 'number',
                    label: 'Mark',
                    required: true,
                    min: 0,
                    max: 100,
                    claim: true,
                  },
                  {
                    key: 'evidence',
                    kind: 'object',
                    label: 'Coursework behind the mark',
                    help: 'A mark is a number a reader has to take on trust. The artefact is what makes it evidence.',
                    fields: [
                      {
                        key: 'src',
                        kind: 'asset',
                        media: 'image',
                        label: 'Image',
                        required: true,
                      },
                      localised('caption', 'Caption', {required: true}),
                    ],
                  },
                ],
              },
            },
            {
              key: 'highlights',
              kind: 'list',
              label: 'Highlights',
              addLabel: 'Add a highlight',
              of: {kind: 'localized', label: 'Highlight'},
            },
          ],
        },
      },
    ],
  },
  {
    file: 'interests.json',
    section: 'Off duty',
    blurb: 'What you do when you are not working.',
    warning: null,
    listKey: 'interests',
    fields: [
      {
        key: 'interests',
        kind: 'list',
        label: 'Interests',
        addLabel: 'Add an interest',
        of: {
          kind: 'object',
          titleFrom: 'label',
          subtitleFrom: 'note',
          fields: [
            {
              key: 'id',
              kind: 'id',
              label: 'Identifier',
              required: true,
              unique: true,
            },
            localised('label', 'Interest', {required: true}),
            localised('note', 'The specific', {
              help: '"Television" says nothing; "Better Call Saul" says a great deal.',
            }),
            {
              key: 'logo',
              kind: 'asset',
              media: 'image',
              label: 'Badge or crest',
              help: 'A club crest is a trademark. Use the real one or none; an approximation is worse than nothing.',
            },
          ],
        },
      },
    ],
  },
];

/// The documents, by file name.
export const documentsByFile = new Map(
  documents.map((document) => [document.file, document]),
);

/// Every file the panel and the publish endpoint recognise.
export const editableFiles = documents.map((document) => document.file);
