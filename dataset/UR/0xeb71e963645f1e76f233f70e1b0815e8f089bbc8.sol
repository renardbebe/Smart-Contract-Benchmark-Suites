 

pragma solidity ^0.4.21;

 

contract ERC20Token {
    function transfer(address to, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
}

contract SimplePHXExchange {
    
     
     
     
    uint public ScaleFactor = 10 ** 18;  
    
     
     
    address[] public tknOfferors;
	mapping(address => uint256) public tknAddrNdx;

	 
	mapping(address => uint256) public tknTokensOffered;
	mapping(address => uint256) public tknPricePerToken;  

     
     
    address[] public ethOfferors;
	mapping(address => uint256) public ethAddrNdx;

	 
	mapping(address => uint256) public ethEtherOffered;
	mapping(address => uint256) public ethPricePerToken;  
     

    ERC20Token public phxCoin;

    function SimplePHXExchange() public {
        phxCoin = ERC20Token(0x14b759A158879B133710f4059d32565b4a66140C);  
        tknOfferors.push(0x0);  
        ethOfferors.push(0x0);  
    }

    function offerTkn(uint _tokensOffered, uint _tokenPrice) public {
        require(_humanSender(msg.sender));
        require(tknAddrNdx[msg.sender] == 0);  
        require(0 < _tokensOffered);  
        require(phxCoin.transferFrom(msg.sender, this, _tokensOffered));  
        tknTokensOffered[msg.sender] = _tokensOffered;
        tknPricePerToken[msg.sender] = _tokenPrice;  
        tknOfferors.push(msg.sender);
        tknAddrNdx[msg.sender] = tknOfferors.length - 1;
    }
    
    function offerEth(uint _tokenPrice) public payable {
        require(_humanSender(msg.sender));
        require(ethAddrNdx[msg.sender] == 0);  
        require(0 < msg.value);  
        ethEtherOffered[msg.sender]  = msg.value;
        ethPricePerToken[msg.sender] = _tokenPrice;  
        ethOfferors.push(msg.sender);
        ethAddrNdx[msg.sender] = ethOfferors.length - 1;
    }

    function cancelTknOffer() public {
        if(tknAddrNdx[msg.sender] == 0) return;  
        phxCoin.transfer(msg.sender, tknTokensOffered[msg.sender]);  
        _cancelTknOffer(msg.sender);
    }

    function _cancelTknOffer(address _offeror) internal {
        delete tknTokensOffered[_offeror];
        delete tknPricePerToken[_offeror];

        uint ndx = tknAddrNdx[_offeror];

         
         
        tknOfferors[ndx] = tknOfferors[tknOfferors.length - 1];
        tknAddrNdx[tknOfferors[tknOfferors.length - 1]] = ndx;
        delete tknOfferors[tknOfferors.length - 1];
        delete tknAddrNdx[_offeror];  
    }

    function cancelEthOffer() public {
        if(ethAddrNdx[msg.sender] == 0) return;  
        msg.sender.transfer(ethEtherOffered[msg.sender]);  
        _cancelEthOffer(msg.sender);
    }

    function _cancelEthOffer(address _offeror) internal {
        delete ethEtherOffered[_offeror];
        delete ethPricePerToken[_offeror];
        
        uint ndx = ethAddrNdx[_offeror];

         
         
        ethOfferors[ndx] = ethOfferors[ethOfferors.length - 1];
        ethAddrNdx[ethOfferors[ethOfferors.length - 1]] = ndx;
        delete ethOfferors[ethOfferors.length - 1];
        delete ethAddrNdx[_offeror];  
    }
    
    function buyTkn(uint _ndx) payable public {
        require(_humanSender(msg.sender));
        address _offeror = tknOfferors[_ndx];
        uint _purchasePrice = tknTokensOffered[_offeror] * tknPricePerToken[_offeror] / ScaleFactor;  
        require(msg.value >= _purchasePrice);
        require(phxCoin.transfer(msg.sender, tknTokensOffered[_offeror]));  
        _offeror.transfer(_purchasePrice);
        _cancelTknOffer(_offeror);
    }
    
    function buyEth(uint _ndx) public {
        require(_humanSender(msg.sender));
        address _offeror = ethOfferors[_ndx];
        uint _purchasePrice = ethEtherOffered[_offeror] * ethPricePerToken[_offeror] / ScaleFactor;   
        require(phxCoin.transferFrom(msg.sender, _offeror, _purchasePrice));  
        msg.sender.transfer(ethEtherOffered[_offeror]);
        _cancelEthOffer(_offeror);
    }
    
    function updateTknPrice(uint _newPrice) public {
         
        require(tknTokensOffered[msg.sender] != 0); 
        tknPricePerToken[msg.sender] = _newPrice;
    }
    
    function updateEthPrice(uint _newPrice) public {
         
        require(ethEtherOffered[msg.sender] != 0); 
        ethPricePerToken[msg.sender] = _newPrice;
    }
    
     
    
    function getNumTknOfferors() public constant returns (uint _numOfferors) {
        return tknOfferors.length;  
    }
    
    function getTknOfferor(uint _ndx) public constant returns (address _offeror) {
        return tknOfferors[_ndx];
    }
    
    function getTknOfferPrice(uint _ndx) public constant returns (uint _tokenPrice) {
        return tknPricePerToken[tknOfferors[_ndx]];
    }
    
    function getTknOfferAmount(uint _ndx) public constant returns (uint _tokensOffered) {
        return tknTokensOffered[tknOfferors[_ndx]];
    }
    
    function getNumEthOfferors() public constant returns (uint _numOfferors) {
        return ethOfferors.length;  
    }
    
    function getEthOfferor(uint _ndx) public constant returns (address _offeror) {
        return ethOfferors[_ndx];
    }
    
    function getEthOfferPrice(uint _ndx) public constant returns (uint _etherPrice) {
        return ethPricePerToken[ethOfferors[_ndx]];
    }
    
    function getEthOfferAmount(uint _ndx) public constant returns (uint _etherOffered) {
        return ethEtherOffered[ethOfferors[_ndx]];
    }
    
     
    
     
     
     
    function _humanSender(address _from) private view returns (bool) {
      uint codeLength;
      assembly {
          codeLength := extcodesize(_from)
      }
      return (codeLength == 0);  
    }
}