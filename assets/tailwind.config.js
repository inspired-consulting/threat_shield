// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const plugin = require("tailwindcss/plugin");
const fs = require("fs");
const path = require("path");

module.exports = {
  content: ["./js/**/*.js", "../lib/*_web.ex", "../lib/*_web/**/*.*ex"],
  theme: {
    extend: {
      fontFamily: {
        sans: ["SpaceGrotesk", "sans-serif"],
      },
      colors: {
        primary: {
          100: "#F8F6FB",
          200: "#E1D6F6",
          300: "#A583E5",
          400: "#8759DD",
          500: "#6930D4",
          600: "#5426AA",
          700: "#3F1D7F",
          800: "#2A1355",
          900: "#150A2A",
        },
        secondary: {
          400: "#D1D5DB",
        },
        gray: {
          100: "#EDEDED",
          200: "#D7D8DF",
          300: "#C2C5D0",
          400: "#AEB1C0",
          500: "#9396A7",
          600: "#7E8291",
          700: "#7E8291",
          800: "#7E8291",
          900: "#1A1B1F",
        },
        neutral: {
          100: "#F2F7FF",
          200: "#B4CBF5",
          300: "#8FB1EF",
          400: "#6997EA",
          500: "#1A1B1F",
          600: "#3664B7",
          700: "#294B8A",
          800: "#1B325C",
          900: "#001233",
        },
        green: {
          100: "#F3FFF2",
          200: "#DEF5DD",
          300: "#9BE29A",
          400: "#7AD878",
          500: "#59CE56",
          600: "#47A545",
          700: "#357C34",
          800: "#245222",
          900: "#013300",
        },
        orange: {
          500: "#E89E2E",
        },
        red: {
          100: "#FFF2F3",
          200: "#F3B1B5",
          300: "#EE8B91",
          400: "#E8646C",
          500: "#E23D47",
          600: "#B53139",
          700: "#88252B",
          800: "#5A181C",
          900: "#330003",
        },
      },
    },
    container: {
      padding: {
        DEFAULT: "1rem",
        sm: "2rem",
        md: "2rem",
        lg: "4rem",
        xl: "5rem",
        "2xl": "6rem",
      },
    },
  },
  plugins: [
    require("@tailwindcss/forms"),
    // Allows prefixing tailwind classes with LiveView classes to add rules
    // only when LiveView classes are applied, for example:
    //
    //     <div class="phx-click-loading:animate-ping">
    //
    plugin(({ addVariant }) =>
      addVariant("phx-no-feedback", [".phx-no-feedback&", ".phx-no-feedback &"])
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-click-loading", [
        ".phx-click-loading&",
        ".phx-click-loading &",
      ])
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-submit-loading", [
        ".phx-submit-loading&",
        ".phx-submit-loading &",
      ])
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-change-loading", [
        ".phx-change-loading&",
        ".phx-change-loading &",
      ])
    ),

    // Embeds Heroicons (https://heroicons.com) into your app.css bundle
    // See your `CoreComponents.icon/1` for more information.
    //
    plugin(function ({ matchComponents, theme }) {
      let iconsDir = path.join(__dirname, "./vendor/heroicons/optimized");
      let values = {};
      let icons = [
        ["", "/24/outline"],
        ["-solid", "/24/solid"],
        ["-mini", "/20/solid"],
      ];
      icons.forEach(([suffix, dir]) => {
        fs.readdirSync(path.join(iconsDir, dir)).map((file) => {
          let name = path.basename(file, ".svg") + suffix;
          values[name] = { name, fullPath: path.join(iconsDir, dir, file) };
        });
      });
      matchComponents(
        {
          hero: ({ name, fullPath }) => {
            let content = fs
              .readFileSync(fullPath)
              .toString()
              .replace(/\r?\n|\r/g, "");
            return {
              [`--hero-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
              "-webkit-mask": `var(--hero-${name})`,
              mask: `var(--hero-${name})`,
              "mask-repeat": "no-repeat",
              "background-color": "currentColor",
              "vertical-align": "middle",
              display: "inline-block",
              width: theme("spacing.5"),
              height: theme("spacing.5"),
            };
          },
        },
        { values }
      );
    }),
  ],
};
