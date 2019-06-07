const o = {};

o.__proto__ = {
  foo(){
    console.log('this is foo');
  }
};


o.foo();

Object.setPrototypeOf(o, {
  foo: function () {
    console.log('this is bar')
  }
});

o.foo();