--!strict

export type Callback<T... = (...any)> = (T...) -> ()

export type Node<T... = (...any)> = {
	_prev: Node<T...>,
	_next: Node<T...>,
}

export type Connection<T... = (...any)> = {
	Disconnect: (self: Connection<T...>) -> (),

	_prev: Node<T...>,
	_next: Node<T...>,

	_callback: Callback<any>?,
	_once: boolean?,
	_thread: thread?,	
}

export type Signal<T... = (...any)> = {
	Connect: (self: Signal<T...>, callback: Callback<T...>) -> Connection<T...>,
	Once: (self: Signal<T...>, callback: Callback<T...>) -> Connection<T...>,
	Fire: (self: Signal<T...>, T...) -> (),
	Wait: (self: Signal<T...>) -> T...,
	Destroy: (self: Signal<T...>) -> (),

	New: () -> Signal<T...>,

	_prev: Node<T...>,
	_next: Node<T...>,
}
return 0