# React-treeview [![npm version](https://badge.fury.io/js/react-treeview.svg)](https://www.npmjs.com/package/react-treeview) [![Bower version](https://badge.fury.io/bo/react-treeview.svg)](http://badge.fury.io/bo/react-treeview)

Easy, light, flexible treeview made with [React](http://facebook.github.io/react/).

[Demos](https://cdn.rawgit.com/chenglou/react-treeview/aa72ed8b9e0b31fabc09e2f8bd4084947d48bb09/demos/index.html) from the [demos folder](https://github.com/chenglou/react-treeview/tree/aa72ed8b9e0b31fabc09e2f8bd4084947d48bb09/demos).

## install

Npm:
```sh
npm install react-treeview
```

Bower:
```sh
bower install react-treeview
```

The CSS file:

```html
<link rel="stylesheet" type="text/css" href="path/to/react-treeview.css">
```

## API

#### &lt;TreeView />
The component accepts [these props](https://github.com/chenglou/react-treeview/blob/aa72ed8b9e0b31fabc09e2f8bd4084947d48bb09/src/react-treeview.jsx#L5-L9).

- `collapsed`: whether the node is collapsed or not.
- `defaultCollapsed`: the [uncontrolled](http://facebook.github.io/react/docs/forms.html#uncontrolled-components) equivalent to `collapsed`.
- `nodeLabel`: the component or string (or anything renderable) that's displayed beside the TreeView arrow.
- `itemClassName`: the class name of the tree view item div.

TreeViews can be naturally nested.

The extra properties transferred onto the arrow, so all attributes and events naturally work on it.

## Styling
The CSS is flexible, commented and made to be easily customized. Feel free to inspect the demo's classes and check the [short CSS code](https://github.com/chenglou/react-treeview/blob/aa72ed8b9e0b31fabc09e2f8bd4084947d48bb09/react-treeview.css).

## Build It Yourself/Run the Demos

Build: `npm install && npm run prerelease`

Demos: `npm install && npm start && open http://localhost:3000`

## License

MIT.
