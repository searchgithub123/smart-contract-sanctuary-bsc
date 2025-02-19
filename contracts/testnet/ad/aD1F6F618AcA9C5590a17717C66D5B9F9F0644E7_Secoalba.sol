// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Secoalba {

    //devuelve dueño de la dirección del contrato
    address public owner;
    // % de comisión de que cobraremos en la app
    uint private secureAddPercent = 5;

    //dirección inválida, (es una dirección de validación(0x0000..))
    address private noOne = address(0);

    //instanciar clase =>  (Tipo de classe, visibilidad, nombre del objeto) 
    IERC20 private token;

    //Estructura del usuario 
    struct User {
        string name;
        string contact; 
        bool updated;
        uint total_products;
        uint[] products;
    }

    //Structura del producto
    struct Product {
        string name;
        string desc; //descripción
        string section;
        uint price;
        address owner; //propietario del producto
        address reserved_by; //quien ha comprado el producto
    }

    //VARIABLES

    //Guardamos el  produto en un array
    Product[] private products;

    //accedemos a un usuario a traves de su dirección
    mapping(address => User) public users;

    uint private _totalUsers;
    

    //EVENTOS (si pasa x quiero que emitas un evento; si compras algo se emita que has comoprado)
    //cuando un usuario compra un producto (quien lo ha comprado (se filtra), a quien, precio)
    event ProductPurchased(address indexed user, address owner, uint price);

    //usuario agrega un producto (quien lo ha creado, nombre, precio)
    event ProductAdded(address indexed owner, string name, uint price);


    constructor (address _token) {
        owner = msg.sender;
        token = IERC20(_token);
        _totalUsers = 0;
    }
 


    //cambiar % de comisión
    function setSecureAddPercent(uint percent) public isOwner {
        secureAddPercent = percent;

    }


    //recibir el % de la comisión
    function getSecureAddPercent() private isOwner view returns(uint) {
        return secureAddPercent;
    }


    //devuelve el valor del % en función del prucunto a comprar
    function __percentValue(uint _amount) public view returns (uint) {
        return(secureAddPercent * _amount) / 100;
    }


    //devuelve el valor en weis (pure: no permite utilizar variables del contrato,solo de la función)
    function __amount(uint _amount) private pure returns(uint) {
        return _amount * (10**18);
    }



    //función para agregar un producto (memory: no vamos a guardar nada en el contrato)
    function addProduct(string memory name,
                        string memory desc, 
                        string memory section, 
                        uint price) public {

        //(dirrección al que se le envia el % de la comisión, precio, quien agrega el produncto)
        transferTokens(address(this), __amount(__percentValue(price)), msg.sender);
        products.push(Product(name, desc, section, __amount(price), msg.sender, noOne));
        //emitimos evento para declarar que se ha agregado un producto nuevo en la web
        emit ProductAdded(msg.sender, name, __amount(price));
    }



    //función transferir tokens (donde los vamos a transferir, precio, comprador)
    //Nos sirve para cobrar las comisiones cuando se agrega un producto 
    //y para transferir el dinero al usuario que ha vendido su producto

    function transferTokens(address _owner, uint _price, address _buyer) private {
        //comprobación del balance de la persona que compra
        require(_price <= token.balanceOf(_buyer), 'Insuficientes tokens para transferir');
        //comprobar el el buyer a dado permisos al contato(this)
        require(token.allowance(_buyer, address(this)) >= _price, 'No tienes suficientes tokens permitos');

        bool sent = token.transferFrom(_buyer, _owner, _price);
        require(sent, 'Not sent');
    }

    //función para comprar el producto
    function buyProduct(uint product_id) public {
        Product storage product = products[product_id];
        //comprar que el que llama a la función sea distinto al dueño del producto
        require(msg.sender != product.owner, 'No puedes comprar tus propios productos');
        //(recibe, $, envia (el que llama))
        transferTokens(product.owner, product.price, msg.sender);
        //Actualizar contador de compras
        User storage buyer = users[msg.sender];
        buyer.total_products +=1;
        //añadir producto coprado
        buyer.products.push(product_id);
        //actualizamos la compra del producto para indicar que está reservado
        product.reserved_by = msg.sender;

        //emitimo un evento indicando que se ha comprado un producto
        //(quien lo compra, dueño del producto, $)
        emit ProductPurchased(msg.sender, product.owner, product.price);
    } 


    //cantidad de usuarios totales(se actualoiza cuando alguien se registra)
    function totalUsers() public view returns (uint) {
        return _totalUsers;
    }

    //lista de productos totales, solo se utiliza para lectura
    function getProducts() public view returns(Product[] memory){
        return products;
    }

    //devuelve un producto en particular
    function getProduct(uint product_id) public view returns(Product memory){
        return products [product_id];
    }

    //nos devuelve un usuario en concreto
    function getUser(address userAddress) public view returns(User memory){
        return users[userAddress];
    }


    //función para retinar BNB de nuestro contrato (por si nos hacen donaciones)
    //(dirección a la que queremos enviar los BNB)
    //external=> solo se puede llamar desde fuera, no desde este contrato; desde el frontend(ahorrar fees)

    function withdrawBNB (address payable account)external isOwner {
        //llamamos a la cuenta a la que queremos transferir los tokens(account.call)
        (bool success,) = account.call{value: address(this).balance}("");
        require(success);
    }


    //función para retirar los tokens acumulados de las comisiones (5%)
    //función de IERC20
    function withdraw(address to, uint256 amount) external isOwner{
        require(token.transfer(to, amount));
    }


    //modificador / función restrictiva
    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}