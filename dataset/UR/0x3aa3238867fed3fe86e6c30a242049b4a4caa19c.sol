 

pragma solidity ^0.4.24;


 
contract locaToken {
    function transferFrom(address _from, address _to, uint _value) public returns (bool);
    function allowance(address _owner, address _spender) public view returns (uint);
}

 
library SafeMath {
    function sub(uint _base, uint _value)
    internal
    pure
    returns (uint) {
        assert(_value <= _base);
        return _base - _value;
    }

    function add(uint _base, uint _value)
    internal
    pure
    returns (uint _ret) {
        _ret = _base + _value;
        assert(_ret >= _base);
    }

    function div(uint _base, uint _value)
    internal
    pure
    returns (uint) {
        assert(_value > 0 && (_base % _value) == 0);
        return _base / _value;
    }

    function mul(uint _base, uint _value)
    internal
    pure
    returns (uint _ret) {
        _ret = _base * _value;
        assert(0 == _base || _ret / _base == _value);
    }
}



 

contract Donation  {
    using SafeMath for uint;
     
    locaToken private token = locaToken(0xcDf9bAff52117711B33210AdE38f1180CFC003ed);
    address  private owner;

    uint private _tokenGift;
     
    event Donated(address indexed buyer, uint tokens);
      
    uint private _tokenDonation;
  

     
    constructor() public {

        owner = msg.sender; 
    }


    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
     
    modifier allowStart() {
        require(_tokenDonation == 0);
        _;
    }
     
    modifier allowDonation(){
        require(_tokenDonation >= 25000000000);
        _;
    }
     
     
    modifier validDonation {
        require (msg.value >= 20000000000000000 && msg.value <= 30000000000000000);                                                                                        
        _;
    }


    function startDonation() public onlyOwner allowStart returns (uint) {

        _tokenDonation = token.allowance(owner, address(this));
    }


    function DonateEther() public allowDonation validDonation payable {

        
        _tokenGift = 25000000000;
        _tokenDonation = _tokenDonation.sub(_tokenGift);
        
        emit Donated(msg.sender, _tokenGift);

        token.transferFrom(owner, msg.sender, _tokenGift);

        

    }

     
    function () public payable {
        revert();
    }


    function TokenBalance () public view returns(uint){

        return _tokenDonation;

    }

     
    function getDonation(address _to) public onlyOwner {
       
        _to.transfer(address(this).balance);
    
    } 

    function CloseDonation() public onlyOwner {

        selfdestruct(owner);
    }

}