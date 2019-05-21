/// FOURJS_START_COPYRIGHT(D,2015)
/// Property of Four Js*
/// (c) Copyright Four Js 2015, 2019. All Rights Reserved.
/// * Trademark of Four Js Development Tools Europe Ltd
///   in the United States and elsewhere
/// 
/// This file can be modified by licensees according to the
/// product manual.
/// FOURJS_END_COPYRIGHT

"use strict";

modulum('MyStartMenuGroupWidget', ['WidgetGroupBase', 'WidgetFactory'],
  function(context, cls) {

    /**
     * MyStartMenuGroup widget.
     * @class MyStartMenuGroupWidget
     * @memberOf classes
     * @extends classes.WidgetGroupBase
     */
    cls.MyStartMenuGroupWidget = context.oo.Class(cls.StartMenuGroupWidget, function($super) {
      return /** @lends classes.MyStartMenuGroupWidget.prototype */ {
        __name: 'StartMenuGroupWidget',

        /**
         * Image of the startMenu command
         * @protected
         * @type {classes.ImageWidget}
         */
        _image: null,

        /**
         * @inheritDoc
         */
        _initElement: function() {
          $super._initElement.call(this);
          this._element.classList.toggle('gbc_open'); /* NJM: Force Group to Start Open */
        }
      };
    });
    cls.WidgetFactory.registerBuilder('StartMenuGroup', cls.MyStartMenuGroupWidget);
  });
