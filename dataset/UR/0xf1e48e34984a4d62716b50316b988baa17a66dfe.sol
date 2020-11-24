 

pragma solidity ^0.4.18;

contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

library TiposCompartidos {
    enum TipoPremio {none,free,x2,x3,x5, surprise }

    struct Celda {
        address creador;
        uint polenPositivos;
        uint polenNegativos;
        uint256 fechaCreacion;
        uint primeraPosicion;
        uint segundaPosicion;
        uint terceraPosicion;
        uint cuartaPosicion;
        uint quintaPosicion;
        uint sextaPosicion;
        TipoPremio tipo;
        bool premio;
    }
    
}

contract BeeGame is owned {
    
    uint256 internal sellPrice;
    uint256 internal buyPrice;
    uint internal numeroCeldas;
    string internal name;
    string internal symbol;
    uint8 internal decimals;
    uint internal numeroUsuarios;
    uint fechaTax;

    mapping (address => uint) balanceOf;

    address[] indiceUsuarios;
    
    mapping (uint256 => TiposCompartidos.Celda) celdas;
    
    uint256[] indiceCeldas;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event TransferKO(address indexed from, address indexed to, uint256 value);
    
    function BeeGame (
        uint256 initialSupply,
        uint256 newSellPrice,
        uint256 newBuyPrice,
        uint _fechaTax) {
        fechaTax = _fechaTax;
        balanceOf[owner] = initialSupply;
        setPrices(newSellPrice,newBuyPrice);
        numeroCeldas = 0;
        name = "Beether";
        symbol = "beeth"; 
        decimals = 2;
        TiposCompartidos.Celda memory celda = TiposCompartidos.Celda({
            creador:msg.sender,
            polenPositivos : 0, 
            polenNegativos : 3,
            fechaCreacion: 1509302402021,
            primeraPosicion : 0,
            segundaPosicion : 0,
            terceraPosicion : 0,
            cuartaPosicion : 0,
            quintaPosicion : 0,
            sextaPosicion : 0,
            tipo:TiposCompartidos.TipoPremio.none,
            premio:false
        });
        indiceCeldas.push(1509302402021);
        numeroCeldas = numeroCeldas + 1;
        celdas[1509302402021] = celda;
    }

    function buy() payable returns (uint amount) {
        amount = msg.value / buyPrice;         
        require(balanceOf[owner] >= amount); 
        _transfer(owner, msg.sender, amount);
        incluirUsuario(msg.sender);
        Transfer(owner, msg.sender, amount); 
        return amount;                         
    }

    function incluirUsuario(address usuario){
        bool encontrado = false;
        for (uint i = 0; i < numeroUsuarios; i++) {
            address usuarioT = indiceUsuarios[i];
            if (usuarioT == usuario){
                encontrado = true;
            }
        }
        if(!encontrado){
            indiceUsuarios.push(usuario);
            numeroUsuarios++;
        }
    }

    function cobrarImpuesto(uint _fechaTax) onlyOwner {
        for (uint i = 0; i < numeroUsuarios; i++) {
            address usuario = indiceUsuarios[i];
            if (balanceOf[usuario] > 0){
                _transfer(usuario, owner, 1);
            }
        }
        fechaTax = _fechaTax;
    }

    function crearCelda(uint _polenes, uint256 _fechaCreacion, uint posicion, uint _celdaPadre, uint _celdaAbuelo, TiposCompartidos.TipoPremio tipo) {
        require(balanceOf[msg.sender]>=3);
        require(_polenes == 3);
        require(_celdaPadre != 0);
        require((posicion >= 0 && posicion < 7) || (posicion == 0 && msg.sender == owner));
        require(((tipo == TiposCompartidos.TipoPremio.free || tipo == TiposCompartidos.TipoPremio.x2 || tipo == TiposCompartidos.TipoPremio.x3 || tipo == TiposCompartidos.TipoPremio.x5 || tipo == TiposCompartidos.TipoPremio.surprise) && msg.sender == owner) || tipo == TiposCompartidos.TipoPremio.none);
        TiposCompartidos.Celda memory celdaPadre = celdas[_celdaPadre];
        require(
            ((posicion == 1 && celdaPadre.primeraPosicion == 0) || celdas[celdaPadre.primeraPosicion].tipo != TiposCompartidos.TipoPremio.none ) || 
            ((posicion == 2 && celdaPadre.segundaPosicion == 0) || celdas[celdaPadre.segundaPosicion].tipo != TiposCompartidos.TipoPremio.none ) || 
            ((posicion == 3 && celdaPadre.terceraPosicion == 0) || celdas[celdaPadre.terceraPosicion].tipo != TiposCompartidos.TipoPremio.none ) || 
            ((posicion == 4 && celdaPadre.cuartaPosicion == 0)  || celdas[celdaPadre.cuartaPosicion].tipo != TiposCompartidos.TipoPremio.none ) || 
            ((posicion == 5 && celdaPadre.quintaPosicion == 0)  || celdas[celdaPadre.quintaPosicion].tipo != TiposCompartidos.TipoPremio.none ) || 
            ((posicion == 6 && celdaPadre.sextaPosicion == 0) || celdas[celdaPadre.sextaPosicion].tipo != TiposCompartidos.TipoPremio.none )
        );
        TiposCompartidos.Celda memory celda;
        TiposCompartidos.TipoPremio tipoPremio;
        if (celdas[_fechaCreacion].fechaCreacion == _fechaCreacion) {
            celda = celdas[_fechaCreacion];
            celda.creador = msg.sender;
            celda.premio = false;
            tipoPremio = celda.tipo;
            celda.tipo = TiposCompartidos.TipoPremio.none;
        } else {
            if (msg.sender != owner) {
                celda = TiposCompartidos.Celda({
                    creador:msg.sender,
                    polenPositivos : 0, 
                    polenNegativos : _polenes,
                    fechaCreacion: _fechaCreacion,
                    primeraPosicion : 0,
                    segundaPosicion : 0,
                    terceraPosicion : 0,
                    cuartaPosicion : 0,
                    quintaPosicion : 0,
                    sextaPosicion : 0,
                    tipo:tipo,
                    premio:false
                });
            }else {
                celda = TiposCompartidos.Celda({
                    creador:msg.sender,
                    polenPositivos : 0, 
                    polenNegativos : _polenes,
                    fechaCreacion: _fechaCreacion,
                    primeraPosicion : 0,
                    segundaPosicion : 0,
                    terceraPosicion : 0,
                    cuartaPosicion : 0,
                    quintaPosicion : 0,
                    sextaPosicion : 0,
                    tipo:tipo,
                    premio:true
                });
            }
            indiceCeldas.push(_fechaCreacion);
            numeroCeldas = numeroCeldas + 1;
        }
        celdas[_fechaCreacion] = celda;
        TiposCompartidos.Celda memory celdaAbuelo = celdas[_celdaAbuelo];
        uint multiplicador = 1;
        address repartidor = msg.sender;
        if (tipoPremio == TiposCompartidos.TipoPremio.x2 && !celda.premio) {
            multiplicador = 2;
            repartidor = owner;
        } else if (tipoPremio == TiposCompartidos.TipoPremio.x3 && !celda.premio) {
            multiplicador = 3;
            repartidor = owner;
        } else if (tipoPremio == TiposCompartidos.TipoPremio.x5 && !celda.premio) {
            multiplicador = 5;
            repartidor = owner;
        }  else if (tipoPremio == TiposCompartidos.TipoPremio.free && !celda.premio) {
            repartidor = owner;
        }
        if (posicion == 1 && celdaPadre.primeraPosicion == 0) {
            celdaPadre.primeraPosicion = _fechaCreacion;   
        }else if (posicion == 2 && celdaPadre.segundaPosicion == 0 ) {
            celdaPadre.segundaPosicion = _fechaCreacion;
        }else if (posicion == 3 && celdaPadre.terceraPosicion == 0) {
            celdaPadre.terceraPosicion = _fechaCreacion;
        }else if (posicion == 4 && celdaPadre.cuartaPosicion == 0) {
            celdaPadre.cuartaPosicion = _fechaCreacion;
        }else if (posicion == 5 && celdaPadre.quintaPosicion == 0) {
            celdaPadre.quintaPosicion = _fechaCreacion;
        }else if (posicion == 6 && celdaPadre.sextaPosicion == 0) {
            celdaPadre.sextaPosicion = _fechaCreacion;
        }
        if (_celdaAbuelo != 0 && !celda.premio) {
            _transfer(repartidor,celdaPadre.creador,2 * multiplicador);
            celdaPadre.polenPositivos = celdaPadre.polenPositivos + (2 * multiplicador);
            celdaAbuelo.polenPositivos = celdaAbuelo.polenPositivos + (1 * multiplicador);
            _transfer(repartidor,celdaAbuelo.creador,1 * multiplicador);
            celdas[celdaAbuelo.fechaCreacion] = celdaAbuelo;
        }else if (!celda.premio) {
            _transfer(repartidor,celdaPadre.creador,3 * multiplicador);
            celdaPadre.polenPositivos = celdaPadre.polenPositivos + ( 3 * multiplicador);
        }
        celdas[celdaPadre.fechaCreacion] = celdaPadre;
    }

    function getCelda(uint index) returns (address creador, uint polenPositivos, uint polenNegativos, uint fechaCreacion, 
                                            uint primeraPosicion, uint segundaPosicion, uint terceraPosicion,
                                            uint cuartaPosicion, uint quintaPosicion, uint sextaPosicion, TiposCompartidos.TipoPremio tipo, bool premio) {
        uint256 indexA = indiceCeldas[index];
        TiposCompartidos.Celda memory  celda = celdas[indexA];
        return (celda.creador,celda.polenPositivos,celda.polenNegativos,celda.fechaCreacion,
        celda.primeraPosicion, celda.segundaPosicion, celda.terceraPosicion, celda.cuartaPosicion, 
        celda.quintaPosicion, celda.sextaPosicion, celda.tipo, celda.premio);
    }

    function getBalance(address addr) returns(uint) {
		return balanceOf[addr];
	}

    function getFechaTax() returns(uint) {
        return fechaTax;
    }

    function getNumeroCeldas() returns(uint) {
        return numeroCeldas;
    }

    function getOwner() returns(address) {
        return owner;
    }

    function getRevenue(uint amount) onlyOwner {
        owner.transfer(amount);
    }

    function sell(uint amount){
        require(balanceOf[msg.sender] >= amount);         
        _transfer(msg.sender, owner, amount);
        uint revenue = amount * sellPrice;
        if (msg.sender.send (revenue)) {                
            Transfer(msg.sender, owner, revenue);  
        }else {
            _transfer(owner, msg.sender, amount);
            TransferKO(msg.sender, this, revenue);
        }                                   
    }

    function setFechaTax(uint _fechaTax) onlyOwner {
        fechaTax = _fechaTax;
    }

    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner {
        sellPrice = newSellPrice * 1 finney;
        buyPrice = newBuyPrice * 1 finney;
    }

    function transfer(address _to, uint _value){
        _transfer(msg.sender, _to, _value);
        incluirUsuario(_to);
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);                                
        require(balanceOf[_from] >= _value);                 
        require(balanceOf[_to] + _value > balanceOf[_to]);  
        balanceOf[_from] = balanceOf[_from] - _value;                         
        balanceOf[_to] = balanceOf[_to] + _value;                           
        Transfer(_from, _to, _value);
    }
}