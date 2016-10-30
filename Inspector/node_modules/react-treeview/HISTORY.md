## 0.4.5 (April 18th 2016)
- Fix build output not showing. Sorry!

## 0.4.4 (April 18th 2016)
- Bump React version requirement.

## 0.4.3 (February 7th 2016)
- Support for React 0.14 official.
- New prop `itemClassName` to assign class name on the `TreeView` node itself. #28
- Arrow symbol is now styled via CSS instead of hard-coded inside the DOM. This means you can now use your own styling for the arrow! #27

## 0.4.2 (September 12th 2015)
- Support for React 0.14, beta and rc.

## 0.4.0 (July 31th 2015)
- Repo revamp. No breaking change beside the change in directory structure. New location for npm: `lib/`. Location for bower & others: `build/`. The CSS is on root level.
- Expose `tree-view_item` css class, the immediate child of `.tree-view`, for styling convenience.

## 0.3.12 (May 7th 2015)
- Upgrade React dependency to accept >=0.12.0.

## 0.3.11 (December 2nd 2014)
- Upgrade React to 0.12.1.
- Fix `propTypes` warning.

## 0.3.10 (November 9th 2014)
- Perf improvement.

## 0.3.9 (November 8th 2014)
- Bump React to 0.12.

## 0.3.8 (September 29th 2014)
- Make AMD with Webpack work.
- Bump React version to 0.11.2.

## 0.3.7 (September 17th 2014)
- Support for AMD.

## 0.3.3-0.3.5 (July 8th 2014)
- Fix case-sensitive `require` for Linux.

## 0.3.2 (May 12th 2014)
- Fix bug where `onClick` doesn't trigger.

## 0.3.1 (May 12th 2014)
- New API. Breaking. It's a superset of the previous API, so everything should be reproducible.The new only Only exposes a `TreeView` and let natural recursion construct the tree.
- Bump React version.

### 0.2.1 (September 21st 2013)
- Stable API.

## 0.0.0 (July 13th 2013)
- Initial release.
