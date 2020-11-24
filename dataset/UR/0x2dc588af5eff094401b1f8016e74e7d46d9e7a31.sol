 

pragma solidity ^0.4.11;

contract CardboardUnicorns {
  address public owner;
  function mint(address who, uint value);
  function changeOwner(address _newOwner);
  function withdraw();
  function withdrawForeignTokens(address _tokenContract);
}
contract RealUnicornCongress {
  uint public priceOfAUnicornInFinney;
}
contract ForeignToken {
  function balanceOf(address _owner) constant returns (uint256);
  function transfer(address _to, uint256 _value) returns (bool);
}

contract CardboardUnicornAssembler {
  address public cardboardUnicornTokenAddress;
  address public realUnicornAddress = 0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359;
  address public owner = msg.sender;
  uint public pricePerUnicorn = 1 finney;
  uint public lastPriceSetDate = 0;
  
  event PriceUpdate(uint newPrice, address updater);

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }
  
   
  function changeOwner(address _newOwner) onlyOwner {
    owner = _newOwner;
  }
  function changeTokenOwner(address _newOwner) onlyOwner {
    CardboardUnicorns cu = CardboardUnicorns(cardboardUnicornTokenAddress);
    cu.changeOwner(_newOwner);
  }
  
   
  function changeCardboardUnicornTokenAddress(address _newTokenAddress) onlyOwner {
    CardboardUnicorns cu = CardboardUnicorns(_newTokenAddress);
    require(cu.owner() == address(this));  
    cardboardUnicornTokenAddress = _newTokenAddress;
  }
  
   
  function changeRealUnicornAddress(address _newUnicornAddress) onlyOwner {
    realUnicornAddress = _newUnicornAddress;
  }
  
  function withdraw(bool _includeToken) onlyOwner {
    if (_includeToken) {
       
      CardboardUnicorns cu = CardboardUnicorns(cardboardUnicornTokenAddress);
      cu.withdraw();
    }

     
    owner.transfer(this.balance);
  }
  function withdrawForeignTokens(address _tokenContract, bool _includeToken) onlyOwner {
    ForeignToken token = ForeignToken(_tokenContract);

    if (_includeToken) {
       
      CardboardUnicorns cu = CardboardUnicorns(cardboardUnicornTokenAddress);
      cu.withdrawForeignTokens(_tokenContract);
    }

     
    uint256 amount = token.balanceOf(address(this));
    token.transfer(owner, amount);
  }

   
  function updatePriceFromRealUnicornPrice() {
    require(block.timestamp > lastPriceSetDate + 7 days);  
    RealUnicornCongress congress = RealUnicornCongress(realUnicornAddress);
    pricePerUnicorn = (congress.priceOfAUnicornInFinney() * 1 finney) / 1000;
    PriceUpdate(pricePerUnicorn, msg.sender);
  }
  
   
  function setPrice(uint _newPrice) onlyOwner {
    pricePerUnicorn = _newPrice;
    lastPriceSetDate = block.timestamp;
    PriceUpdate(pricePerUnicorn, msg.sender);
  }
  
   
  function assembleUnicorn() payable {
    if (msg.value >= pricePerUnicorn) {
        CardboardUnicorns cu = CardboardUnicorns(cardboardUnicornTokenAddress);
        cu.mint(msg.sender, msg.value / pricePerUnicorn);
        owner.transfer(msg.value);
    }
  }
  
  function() payable {
      assembleUnicorn();
  }

}