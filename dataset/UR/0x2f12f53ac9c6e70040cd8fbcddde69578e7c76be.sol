 

 

pragma solidity ^0.4.16;


 
contract Token {

	 
	 
	function whoAmI()  constant returns (address) {
	    return msg.sender;
	}

	 
	
	address owner;
	
	function isOwner() returns (bool) {
		if (msg.sender == owner) return true;
		return false;
	}

	 

	 
	event Error(string error);


	 
	mapping (address => uint256) balances;
	mapping (address => mapping (address => uint256)) allowed;
	uint256 public initialSupply;  
	uint256 public totalSupply;
	 
	
	 
	 
	string public name;
	string public symbol;
	uint8 public decimals;
	string public standard = 'H0.1';

	 
	
	 
	 
	
	 
	function balanceOf(address _owner) constant returns (uint256 balance) {
		return balances[_owner];
	}
 
 	 
	function transfer(address _to, uint256 _amount) returns (bool success) {
		if (balances[msg.sender] < _amount) {
			Error('transfer: the amount to transfer is higher than your token balance');
			return false;
		}
		balances[msg.sender] -= _amount;
		balances[_to] += _amount;
		Transfer(msg.sender, _to, _amount);

		return true;
	}
 
 	 
 	 
 	 
 	 
 	 
	function transferFrom(address _from, address _to, uint256 _amount) returns (bool success) {
		if (balances[_from] < _amount) {
			Error('transfer: the amount to transfer is higher than the token balance of the source');
			return false;
		}
		if (allowed[_from][msg.sender] < _amount) {
			Error('transfer: the amount to transfer is higher than the maximum token transfer allowed by the source');
			return false;
		}
		balances[_from] -= _amount;
		balances[_to] += _amount;
		allowed[_from][msg.sender] -= _amount;
		Transfer(_from, _to, _amount);

		return true;
	}
 
 	 
 	 
	function approve(address _spender, uint256 _amount) returns (bool success) {
		allowed[msg.sender][_spender] = _amount;
		Approval(msg.sender, _spender, _amount);
		
		return true;
	}
 
 	 
	function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
		return allowed[_owner][_spender];
	}
	
	 
	function Token() {
		 
		owner = msg.sender;
		
		 
		 

		 
		 

		 
		 

		initialSupply = 50000000 * 1000000;  
		totalSupply = initialSupply;
		
		name = "WorldTrade";
		symbol = "WTE";
		decimals = 6;

		balances[owner] = totalSupply;
		Transfer(this, owner, totalSupply);

		 
	}

	 
	
	 
	event Transfer(address indexed _from, address indexed _to, uint256 _amount);
	
	 
	event Approval(address indexed _owner, address indexed _spender, uint256 _amount);
}


 
contract IFIssuers {
	
	 
	
	 
	function isIssuer(address _issuer) constant returns (bool);
}


contract Asset is Token {
	 
	
	 
	enum assetStatus { Released, ForSale, Unfungible }
	 
	
	struct asst {
		uint256 assetId;
		address assetOwner;
		address issuer;
		string content;  
		uint256 sellPrice;  
		assetStatus status;  
	}

	mapping (uint256 => asst) assetsById;
	uint256 lastAssetId;  
	address public SCIssuers;  
	uint256 assetFeeIssuer;  
	uint256 assetFeeWorldTrade;  
	

	 
	
	 
	function Asset(address _SCIssuers) {
		SCIssuers = _SCIssuers;
	}
	
	 
	function getAssetById(uint256 assetId) constant returns (uint256 _assetId, address _assetOwner, address _issuer, string _content, uint256 _sellPrice, uint256 _status) {
		return (assetsById[assetId].assetId, assetsById[assetId].assetOwner, assetsById[assetId].issuer, assetsById[assetId].content, assetsById[assetId].sellPrice, uint256(assetsById[assetId].status));
	}

	 
	function sendAssetTo(uint256 assetId, address assetBuyer) returns (bool) {
		 
		if (assetId == 0) {
			Error('sendAssetTo: assetId must not be zero');
			return false;
		}

		 
		if (assetsById[assetId].assetOwner != msg.sender) {
			Error('sendAssetTo: the asset does not belong to you, the seller');
			return false;
		}
		
		if (assetsById[assetId].sellPrice > 0) {  
			 
			if (balances[assetBuyer] < assetsById[assetId].sellPrice) {
				Error('sendAssetTo: there is not enough balance from the buyer to get its tokens');
				return false;
			}

			 
			if (allowance(assetBuyer, msg.sender) < assetsById[assetId].sellPrice) {
				Error('sendAssetTo: there is not enough allowance from the buyer to get its tokens');
				return false;
			}

			 
			if (!transferFrom(assetBuyer, msg.sender, assetsById[assetId].sellPrice)) {
				Error('sendAssetTo: transferFrom failed');  
				return false;
			}
		}
		
		 
		assetsById[assetId].status = assetStatus.Unfungible;
		
		 
		assetsById[assetId].assetOwner = assetBuyer;
		
		 
		SendAssetTo(assetId, assetBuyer);
		
		return true;
	}
	
	 
	function buyAsset(uint256 assetId, uint256 amount) returns (bool) {
		 
		if (assetId == 0) {
			Error('buyAsset: assetId must not be zero');
			return false;
		}

		 
		if (assetsById[assetId].status != assetStatus.ForSale) {
			Error('buyAsset: the asset is not for sale');
			return false;
		}
		
		 
		if (assetsById[assetId].sellPrice != amount) {
			Error('buyAsset: the asset price does not match the specified amount');
			return false;
		}
		
		if (assetsById[assetId].sellPrice > 0) {  
			 
			if (balances[msg.sender] < assetsById[assetId].sellPrice) {
				Error('buyAsset: there is not enough token balance to buy this asset');
				return false;
			}
			
			 
			uint256 sellerIncome = assetsById[assetId].sellPrice * (1000 - assetFeeIssuer - assetFeeWorldTrade) / 1000;

			 
			if (!transfer(assetsById[assetId].assetOwner, sellerIncome)) {
				Error('buyAsset: seller token transfer failed');  
				return false;
			}
			
			 
			uint256 issuerIncome = assetsById[assetId].sellPrice * assetFeeIssuer / 1000;
			if (!transfer(assetsById[assetId].issuer, issuerIncome)) {
				Error('buyAsset: issuer token transfer failed');  
				return false;
			}
			
			 
			uint256 WorldTradeIncome = assetsById[assetId].sellPrice * assetFeeWorldTrade / 1000;
			if (!transfer(owner, WorldTradeIncome)) {
				Error('buyAsset: WorldTrade token transfer failed');  
				return false;
			}
		}
				
		 
		assetsById[assetId].status = assetStatus.Unfungible;
		
		 
		assetsById[assetId].assetOwner = msg.sender;
		
		 
		BuyAsset(assetId, amount);
		
		return true;
	}
	
	
	 
	modifier onlyIssuer() {
	    if (!IFIssuers(SCIssuers).isIssuer(msg.sender)) {
	    	Error('onlyIssuer function called by user that is not an authorized issuer');
	    } else {
	    	_;
	    }
	}

	
	 
	function issueAsset(string content, uint256 sellPrice) onlyIssuer internal returns (uint256 nextAssetId) {
		 
		nextAssetId = lastAssetId + 1;
		
		assetsById[nextAssetId].assetId = nextAssetId;
		assetsById[nextAssetId].assetOwner = msg.sender;
		assetsById[nextAssetId].issuer = msg.sender;
		assetsById[nextAssetId].content = content;
		assetsById[nextAssetId].sellPrice = sellPrice;
		assetsById[nextAssetId].status = assetStatus.Released;
		
		 
		lastAssetId++;

		 
		IssueAsset(nextAssetId, msg.sender, sellPrice);
		
		return nextAssetId;
	}
	
	 
	function issueAssetTo(string content, address to) returns (bool) {
		uint256 assetId = issueAsset(content, 0);  
		if (assetId == 0) {
			Error('issueAssetTo: asset has not been properly issued');
			return (false);
		}
		
		 
		return(sendAssetTo(assetId, to));
	}
	
	 
	function setAssetUnfungible(uint256 assetId) returns (bool) {
		 
		if (assetId == 0) {
			Error('setAssetUnfungible: assetId must not be zero');
			return false;
		}

		 
		if (assetsById[assetId].assetOwner != msg.sender) {
			Error('setAssetUnfungible: only owners of the asset are allowed to update its status');
			return false;
		}
		
		assetsById[assetId].status = assetStatus.Unfungible;

		 
		SetAssetUnfungible(assetId, msg.sender);
		
		return true;
	}

	 
	function setAssetPrice(uint256 assetId, uint256 sellPrice) returns (bool) {
		 
		if (assetId == 0) {
			Error('setAssetPrice: assetId must not be zero');
			return false;
		}

		 
		if (assetsById[assetId].assetOwner != msg.sender) {
			Error('setAssetPrice: only owners of the asset are allowed to set its price and update its status');
			return false;
		}
		
		assetsById[assetId].sellPrice = sellPrice;
		assetsById[assetId].status = assetStatus.ForSale;

		 
		SetAssetPrice(assetId, msg.sender, sellPrice);
		
		return true;
	}

	 
	function setAssetSaleFees(uint256 feeIssuer, uint256 feeWorldTrade) returns (bool) {
		 
		if (!isOwner()) {
			Error('setAssetSaleFees: only Owner is authorized to update asset sale fees.');
			return false;
		}
		
		 
		if (feeIssuer + feeWorldTrade > 1000) {
			Error('setAssetSaleFees: added fees exceed 100.0%. Not updated.');
			return false;
		}
		
		assetFeeIssuer = feeIssuer;
		assetFeeWorldTrade = feeWorldTrade;

		 
		SetAssetSaleFees(feeIssuer, feeWorldTrade);
		
		return true;
	}



	 

	 
	event SendAssetTo(uint256 assetId, address assetBuyer);
	
	 
	event BuyAsset(uint256 assetId, uint256 amount);

	 
	event IssueAsset(uint256 nextAssetId, address assetOwner, uint256 sellPrice);
	
	 
	event SetAssetUnfungible(uint256 assetId, address assetOwner);

	 
	event SetAssetPrice(uint256 assetId, address assetOwner, uint256 sellPrice);
	
	 
	event SetAssetSaleFees(uint256 feeIssuer, uint256 feeWorldTrade);
}