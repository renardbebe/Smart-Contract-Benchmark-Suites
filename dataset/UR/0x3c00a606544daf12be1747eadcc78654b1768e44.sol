 

pragma solidity ^0.4.23;

contract TokenReclaim{
    mapping (address=>string) internal _ethToSphtx;
    mapping (string =>string) internal _accountToPubKey;
    event AccountRegister (address ethAccount, string sphtxAccount, string pubKey);

    function register(string name, string pubKey) public{
        require(bytes(name).length >= 3 && bytes(name).length <= 16);
        bytes memory b = bytes(name);
        require( (b[0] >='a' && b[0] <='z') || (b[0] >='0' && b[0] <= '9'));
        for(uint i=1;i< bytes(name).length; i++){
            require( (b[i] >='a' && b[i] <='z') || (b[i] >='0' && b[i] <= '9') || b[i] == '-' || b[i] =='.'  );
        }
        require(bytes(pubKey).length <= 64 && bytes(pubKey).length >= 50 );

        require(bytes(_ethToSphtx[msg.sender]).length == 0 || keccak256(bytes((_ethToSphtx[msg.sender]))) ==  keccak256(bytes(name))); 

        require(bytes(_accountToPubKey[name]).length == 0 || keccak256(bytes((_ethToSphtx[msg.sender]))) ==  keccak256(bytes(name)));  
        _accountToPubKey[name] = pubKey;
        _ethToSphtx[msg.sender] = name;
        emit AccountRegister(msg.sender, name, pubKey);
    }

    function account(address addr) constant public returns (string){
        return _ethToSphtx[addr];
    }

    function keys(address addr) constant public returns (string){
        return _accountToPubKey[_ethToSphtx[addr]];
    }

    function nameAvailable(string name) constant public returns (bool){
        if( bytes(_accountToPubKey[name]).length != 0 )
           return false;
        if(bytes(name).length < 3 && bytes(name).length > 16)
           return false;
        bytes memory b = bytes(name);
        if( (b[0] < 'a' || b[0] > 'z') && ( b[0] < '0' || b[0] > '9' ) )
           return false;
        for(uint i=1;i< bytes(name).length; i++)
           if( (b[0] < 'a' || b[0] > 'z') && ( b[0] < '0' || b[0] > '9' ) && b[i] != '-' && b[i] != '.' )
              return false;
        return true;
    }


}