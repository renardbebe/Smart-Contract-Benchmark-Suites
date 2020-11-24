 

pragma solidity ^0.4.8;


 
 
 
contract Erc20TokensContract {
    function transfer(address _to, uint256 _value);
     
    function balanceOf(address acc) returns (uint);
}


contract ICO {

    Erc20TokensContract erc20TokensContract;

    address public erc20TokensContractAddress;

    bool erc20TokensContractSet = false;

     
     

    uint public priceToBuyInFinney;  
    uint priceToBuyInWei;  

    address public owner;

    mapping (address => bool) public isManager;  

     
    mapping (uint => uint[3]) public priceChange;
     
    uint public currentPriceChangeNumber = 0;

     
    mapping (uint => uint[4]) public deals;
     
    uint public dealsNumber = 0;

     
    function ICO() { 
        owner = msg.sender;
        isManager[msg.sender] = true;
        priceToBuyInFinney = 0;
         
        priceToBuyInWei = finneyToWei(priceToBuyInFinney);
        priceChange[0] = [priceToBuyInFinney, block.number, block.timestamp];
    }

    function setErc20TokensContract(address _erc20TokensContractAddress) returns (bool){
        if (msg.sender != owner) {throw;}
        if (erc20TokensContractSet) {throw;}
        erc20TokensContract = Erc20TokensContract(_erc20TokensContractAddress);
        erc20TokensContractAddress = _erc20TokensContractAddress;
        erc20TokensContractSet = true;
        TokensContractAddressSet(_erc20TokensContractAddress, msg.sender);
        return true;
    }

    event TokensContractAddressSet(address tokensContractAddress, address setBy);

     
     
     
     
     
     
     
     

    function weiToFinney(uint _wei) internal returns (uint){
        return _wei / (1000000000000000000 * 1000);
    }

    function finneyToWei(uint _finney) internal returns (uint){
        return _finney * (1000000000000000000 / 1000);
    }

     
    event Result(address transactionInitiatedBy, string message);

     
     
    function changeOwner(address _newOwner) returns (bool){
        if (msg.sender != owner) {throw;}
        owner = _newOwner;
        isManager[_newOwner] = true;
        OwnerChanged(msg.sender, owner);
        return true;
    }

    event OwnerChanged(address oldOwner, address newOwner);

     
    function setManager(address _newManager) returns (bool){
        if (msg.sender == owner) {
            isManager[_newManager] = true;
            ManagersChanged("manager added", _newManager);
            return true;
        }
        else throw;
    }

     
    function removeManager(address _manager) returns (bool){
        if (msg.sender == owner) {
            isManager[_manager] = false;
            ManagersChanged("manager removed", _manager);
            return true;
        }
        else throw;
    }

    event ManagersChanged(string change, address manager);

     
    function setNewPriceInFinney(uint _priceToBuyInFinney) returns (bool){

        if (msg.sender != owner || !isManager[msg.sender]) {throw;}

        priceToBuyInFinney = _priceToBuyInFinney;
        priceToBuyInWei = finneyToWei(priceToBuyInFinney);
        currentPriceChangeNumber++;
        priceChange[currentPriceChangeNumber] = [priceToBuyInFinney, block.number, block.timestamp];
        PriceChanged(priceToBuyInFinney, msg.sender);
        return true;
    }

    event PriceChanged(uint newPriceToBuyInFinney, address changedBy);

    function getPriceChange(uint _index) constant returns (uint[3]){
        return priceChange[_index];
         
    }

     
     
     
     
     
     
     
     
    function buyTokens(uint _quantity, uint _priceToBuyInFinney) payable returns (bool){

        if (priceToBuyInFinney <= 0) {throw;}
         

         
         

        if (priceToBuyInFinney != _priceToBuyInFinney) {
             
            throw;
        }

        if (
        (msg.value / priceToBuyInWei) != _quantity
        ) {
             
            throw;
        }
         
         
        uint currentBalance = erc20TokensContract.balanceOf(this);
        if (erc20TokensContract.balanceOf(this) < _quantity) {throw;}
        else {
             
            erc20TokensContract.transfer(msg.sender, _quantity);
             
            if (currentBalance == erc20TokensContract.balanceOf(this)) {
                throw;
            }
             
            dealsNumber = dealsNumber + 1;
            deals[dealsNumber] = [_priceToBuyInFinney, _quantity, block.number, block.timestamp];
             
            Deal(msg.sender, _priceToBuyInFinney, _quantity);
            return true;
        }
    }

     

    event Deal(address to, uint priceInFinney, uint quantity);

    function transferTokensTo(address _to, uint _quantity) returns (bool) {

        if (msg.sender != owner) {throw;}
        if (_quantity <= 0) {throw;}

         
        if (erc20TokensContract.balanceOf(this) < _quantity) {
            throw;

        }
        else {
             
            erc20TokensContract.transfer(_to, _quantity);
             
            TokensTransfer(msg.sender, _to, _quantity);
            return true;
        }
    }

    function transferAllTokensToOwner() returns (bool) {
        return transferTokensTo(owner, erc20TokensContract.balanceOf(this));
    }

    event TokensTransfer (address from, address to, uint quantity);

    function transferTokensToContractOwner(uint _quantity) returns (bool) {
        return transferTokensTo(msg.sender, _quantity);
    }

     
    function withdraw(uint _sumToWithdrawInFinney) returns (bool) {
        if (msg.sender != owner) {throw;}
        if (_sumToWithdrawInFinney <= 0) {throw;}
        if (this.balance < finneyToWei(_sumToWithdrawInFinney)) {
            throw;
        }

        if (msg.sender == owner) { 

            if (!msg.sender.send(finneyToWei(_sumToWithdrawInFinney))) { 
                 
                return false;
            }
            else {
                Withdrawal(msg.sender, _sumToWithdrawInFinney, "withdrawal: success");
                return true;
            }
        }
    }

    function withdrawAllToOwner() returns (bool) {
        return withdraw(this.balance);
    }

    event Withdrawal(address to, uint sumToWithdrawInFinney, string message);

}