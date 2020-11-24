 

pragma solidity ^0.4.19;

 
interface IOwnership {

     
    function isOwner(address _account) public view returns (bool);


     
    function getOwner() public view returns (address);
}


 
contract Ownership is IOwnership {

     
    address internal owner;


     
    function Ownership() public {
        owner = msg.sender;
    }


     
    modifier only_owner() {
        require(msg.sender == owner);
        _;
    }


     
    function isOwner(address _account) public view returns (bool) {
        return _account == owner;
    }


     
    function getOwner() public view returns (address) {
        return owner;
    }
}


 
interface ITransferableOwnership {
    
     
    function transferOwnership(address _newOwner) public;
}


 
contract TransferableOwnership is ITransferableOwnership, Ownership {

     
    function transferOwnership(address _newOwner) public only_owner {
        owner = _newOwner;
    }
}


 
interface IToken { 

     
    function totalSupply() public view returns (uint);


     
    function balanceOf(address _owner) public view returns (uint);


     
    function transfer(address _to, uint _value) public returns (bool);


     
    function transferFrom(address _from, address _to, uint _value) public returns (bool);


     
    function approve(address _spender, uint _value) public returns (bool);


     
    function allowance(address _owner, address _spender) public view returns (uint);
}


 
contract ITokenRetriever {

     
    function retrieveTokens(address _tokenContract) public;
}


 
contract TokenRetriever is ITokenRetriever {

     
    function retrieveTokens(address _tokenContract) public {
        IToken tokenInstance = IToken(_tokenContract);
        uint tokenBalance = tokenInstance.balanceOf(this);
        if (tokenBalance > 0) {
            tokenInstance.transfer(msg.sender, tokenBalance);
        }
    }
}


 
interface IAirdropper {

     
    function drop(IToken _token, address[] _recipients, uint[] _values) public;
}


 
contract Airdropper is TransferableOwnership {

     
    function drop(IToken _token, address[] _recipients, uint[] _values) public only_owner {
        for (uint i = 0; i < _values.length; i++) {
            _token.transfer(_recipients[i], _values[i]);
        }
    }
}


 
contract DCorpAirdropper is Airdropper, TokenRetriever {

     
    function retrieveTokens(address _tokenContract) public only_owner {
        super.retrieveTokens(_tokenContract);
    }


     
    function () public payable {
        revert();
    }
}