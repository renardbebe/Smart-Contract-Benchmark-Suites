 

pragma solidity ^0.4.20;

 

contract ERC20Token {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
}

contract SimplePHXSalesContract {
    
     
     
    uint public ScaleFactor = 10 ** 18;  
    
     
    mapping(uint256 => address) public offerors;
	mapping(address => uint256) public AddrNdx;
    uint public nxtAddr;
    
	 
	mapping(address => uint256) public tokensOffered;
	mapping(address => uint256) public pricePerToken;  

    ERC20Token public phxCoin;

    address public owner;

    function SimplePHXSalesContract() public {
        phxCoin = ERC20Token(0x14b759A158879B133710f4059d32565b4a66140C);  
        owner = msg.sender;
        nxtAddr = 1;  
    }

    function offer(uint _tokensOffered, uint _tokenPrice) public {
        require(_humanSender(msg.sender));
        require(AddrNdx[msg.sender] == 0);  
        require(phxCoin.transferFrom(msg.sender, this, _tokensOffered));
        tokensOffered[msg.sender] = _tokensOffered;
        pricePerToken[msg.sender] = _tokenPrice;  
        offerors[nxtAddr] = msg.sender;
        AddrNdx[msg.sender] = nxtAddr;
        nxtAddr++;
    }

    function _canceloffer(address _offeror) internal {
        delete tokensOffered[_offeror];
        delete pricePerToken[_offeror];
        
        uint Ndx = AddrNdx[_offeror];
        nxtAddr--;

         
         
        if (nxtAddr > 1) {
            offerors[Ndx] = offerors[nxtAddr];
            AddrNdx[offerors[nxtAddr]] = Ndx;
            delete offerors[nxtAddr];
        } else {
            delete offerors[Ndx];
        }
        
        delete AddrNdx[_offeror];  
    }

    function canceloffer() public {
        if(AddrNdx[msg.sender] == 0) return;  
        phxCoin.transfer(msg.sender, tokensOffered[msg.sender]);  
        _canceloffer(msg.sender);
    }
    
    function buy(uint _ndx) payable public {
        require(_humanSender(msg.sender));
        address _offeror = offerors[_ndx];
        uint _purchasePrice = tokensOffered[_offeror] * pricePerToken[_offeror] * ScaleFactor;
        require(msg.value >= _purchasePrice);
        phxCoin.transfer(msg.sender, tokensOffered[_offeror]);
        _offeror.transfer(_purchasePrice);
        _canceloffer(_offeror);
    }
    
    function updatePrice(uint _newPrice) public {
         
        require(tokensOffered[msg.sender] != 0); 
        pricePerToken[msg.sender] = _newPrice;
    }
    
    function getOfferor(uint _ndx) public constant returns (address _offeror) {
        return offerors[_ndx];
    }
    
    function getOfferPrice(uint _ndx) public constant returns (uint _tokenPrice) {
        return pricePerToken[offerors[_ndx]];
    }
    
    function getOfferAmount(uint _ndx) public constant returns (uint _tokensOffered) {
        return tokensOffered[offerors[_ndx]];
    }
    
    function withdrawEth() public {
        owner.transfer(address(this).balance);
    }
    
    function () payable public {
    }
    
     
    function _humanSender(address _from) private view returns (bool) {
      uint codeLength;
      assembly {
          codeLength := extcodesize(_from)
      }
      return (codeLength == 0);  
    }
}