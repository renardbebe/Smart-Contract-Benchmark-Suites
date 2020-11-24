 

pragma solidity ^0.4.24;

contract MemoContract {

    
  event addedJugada (
      uint jugadanro
  );  

   
  uint contadorjugadas = 0;
  

   
  address owner;

   
  struct Jugada {
      uint idjugada;
      uint fecha;  
      string nombre;  
      string mail;  
      uint intentos;  
      uint tiempo;  
      bool valida;  
  }

   
  Jugada[] public jugadas;


   
  mapping( address => bool) public direcciones;



   
  constructor() public {

     
    owner = msg.sender;
    direcciones[owner] = true;

   
  }


 function updateDireccion ( address _direccion , bool _estado)  {
      
     require(msg.sender == owner);

      
     require(_direccion != owner);

     direcciones[_direccion] = _estado;
 } 

function updateJugada( uint _idjugada, bool _valida ) {
    
     
    require(direcciones[msg.sender] );
    
     
    jugadas[_idjugada -1].valida = _valida;
    
}
 

   
  function addJugada ( uint _fecha , string _nombre , string _mail , uint _intentos , uint _tiempo ) public {
      
      require(direcciones[msg.sender] );

      contadorjugadas = contadorjugadas + 1;
      
      jugadas.push (
            Jugada ({
                
                idjugada:contadorjugadas,
                fecha: _fecha,
                nombre:_nombre,
                mail: _mail,
                intentos: _intentos,
                tiempo: _tiempo,
                valida: true
            }));

         
        addedJugada( contadorjugadas );

        }



     
    function fetchJugadas() constant public returns(uint[], uint[], bytes32[], bytes32[], uint[], uint[], bool[]) {
        



            
            
            uint[] memory _idjugadas = new uint[](contadorjugadas);
            uint[] memory _fechas = new uint[](contadorjugadas);
            bytes32[] memory _nombres = new bytes32[](contadorjugadas);
            bytes32[] memory _mails = new bytes32[](contadorjugadas);
            uint[] memory _intentos = new uint[](contadorjugadas);
            uint[] memory _tiempos = new uint[](contadorjugadas);
            bool[] memory _valida = new bool[](contadorjugadas);
        
            for (uint8 i = 0; i < jugadas.length; i++) {

                
                 _idjugadas[i] = jugadas[i].idjugada;
                _fechas[i] = jugadas[i].fecha;
                _nombres[i] = stringToBytes32( jugadas[i].nombre );
                _mails[i] = stringToBytes32( jugadas[i].mail );
                _intentos[i] = jugadas[i].intentos;
                _tiempos[i] = jugadas[i].tiempo;
                _valida[i] = jugadas[i].valida;
                
            }
            
            return ( _idjugadas, _fechas, _nombres, _mails, _intentos, _tiempos, _valida);
        
    }
    
    
    function stringToBytes32(string memory source)  returns (bytes32 result)  {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
        return 0x0;
    }

    assembly {
        result := mload(add(source, 32))
    }
}
    
}