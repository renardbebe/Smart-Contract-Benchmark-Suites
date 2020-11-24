 

pragma solidity ^0.5;
pragma experimental ABIEncoderV2;

contract owned {
    address payable public owner;

    constructor () public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable newOwner) onlyOwner public {
        owner = newOwner;
    }
}

interface IERC20 {
    
   function transfer(address _to, uint256 _value) external;
   function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
}

contract ERC20Holder is owned {
    mapping (address => bool) acceptedTokens;
    function modToken(address token,bool accepted) public onlyOwner {
        acceptedTokens[token] = accepted;
    }
    
    function tokenFallback(address _from, uint _value, bytes memory _data) pure public returns (bytes32 hash) {
        bytes32 tokenHash = keccak256(abi.encodePacked(_from,_value,_data));
        return tokenHash;
    }
    
    function() external  payable {}
    
    function withdraw() onlyOwner public {
        owner.transfer(address(this).balance);
    }
    
    function transferToken (address token,address to,uint256 val) public onlyOwner {
        IERC20 erc20 = IERC20(token);
        erc20.transfer(to,val);
    }
    
}

contract oracleClient is ERC20Holder {
    
    address oracle;
    
    function setOracle(address a) public  onlyOwner {
        
        oracle = a;
    }
}

interface IOracle {
    function  ask (uint8 typeSN, string calldata idPost,string calldata idUser, bytes32 idRequest) external;
}


contract campaign is oracleClient {
    
    struct cpRatio {
        uint256 likeRatio;
        uint256 shareRatio;
        uint256 viewRatio;
    }
    
    struct Campaign {
		address advertiser;
		string dataUrl; 
		uint64 startDate;
		uint64 endDate;
		uint64 nbProms;
		uint64 nbValidProms;
		mapping (uint64 => bytes32) proms;
		Fund funds;
		mapping(uint8 => cpRatio) ratios;
	}
	
	
	struct Fund {
	    address token;
	    uint256 amount;
	}
	
	struct Result  {
	    bytes32 idProm;
	    uint64 likes;
	    uint64 shares;
	    uint64 views;
	}
	
	struct promElement {
	    address influencer;
	    bytes32 idCampaign;
	    bool isAccepted;
	    Fund funds;
	    uint8 typeSN;
	    string idPost;
	    string idUser;
	    uint64 nbResults;
	    mapping (uint64 => bytes32) results;
	    bytes32 prevResult;
	}

	
	mapping (bytes32  => Campaign) public campaigns;
	mapping (bytes32  => promElement) public proms;
	mapping (bytes32  => Result) public results;
	mapping (bytes32 => bool) public isAlreadyUsed;
	
	
	event CampaignCreated(bytes32 indexed id,uint64 startDate,uint64 endDate,string dataUrl);
	event CampaignFundsSpent(bytes32 indexed id );
	event CampaignApplied(bytes32 indexed id ,bytes32 indexed prom );
	
    
    function createCampaign(string memory dataUrl,	uint64 startDate,uint64 endDate) public returns (bytes32 idCampaign) {
        require(startDate > now);
        require(endDate > now);
        require(endDate > startDate);
       
        bytes32 campaignId = keccak256(abi.encodePacked(msg.sender,dataUrl,startDate,endDate,now));
        campaigns[campaignId] = Campaign(msg.sender,dataUrl,startDate,endDate,0,0,Fund(address(0),0));
        emit CampaignCreated(campaignId,startDate,endDate,dataUrl);
        return campaignId;
    }
    
    
    
    function modCampaign(bytes32 idCampaign,string memory dataUrl,	uint64 startDate,uint64 endDate) public {
        require(campaigns[idCampaign].advertiser == msg.sender);
        require(campaigns[idCampaign].startDate > now);
        require(startDate > now);
        require(endDate > now);
        require(endDate > startDate);
       
        campaigns[idCampaign].dataUrl = dataUrl;
        campaigns[idCampaign].startDate = startDate;
        campaigns[idCampaign].endDate = endDate;
        emit CampaignCreated(idCampaign,startDate,endDate,dataUrl);
    }
    
     function priceRatioCampaign(bytes32 idCampaign,uint8 typeSN,uint256 likeRatio,uint256 shareRatio,uint256 viewRatio) public {
        require(campaigns[idCampaign].advertiser == msg.sender);
        require(campaigns[idCampaign].startDate > now);
        campaigns[idCampaign].ratios[typeSN] = cpRatio(likeRatio,shareRatio,viewRatio);
    }
    
  
    
    function fundCampaign (bytes32 idCampaign,address token,uint256 amount) public {
        require(campaigns[idCampaign].endDate > now);
        require(campaigns[idCampaign].funds.token == address(0) || campaigns[idCampaign].funds.token == token);
       
        IERC20 erc20 = IERC20(token);
        erc20.transferFrom(msg.sender,address(this),amount);
        uint256 prev_amount = campaigns[idCampaign].funds.amount;
        
        campaigns[idCampaign].funds = Fund(token,amount+prev_amount);
      
    }
    
    function createPriceFundYt(string memory dataUrl,uint64 startDate,uint64 endDate,uint256 likeRatio,uint256 viewRatio,address token,uint256 amount) public returns (bytes32 idCampaign) {
        bytes32 campaignId = createCampaign(dataUrl,startDate,endDate);
        priceRatioCampaign(campaignId,2,likeRatio,0,viewRatio);
        fundCampaign(campaignId,token,amount);
        return campaignId;
    }
    
    function applyCampaign(bytes32 idCampaign,uint8 typeSN, string memory idPost, string memory idUser) public returns (bytes32 idProm) {
        bytes32 prom = keccak256(abi.encodePacked(typeSN,idPost,idUser));
        require(campaigns[idCampaign].endDate > now);
        require(!isAlreadyUsed[prom]);
        idProm = keccak256(abi.encodePacked( msg.sender,typeSN,idPost,idUser,now));
        proms[idProm] = promElement(msg.sender,idCampaign,false,Fund(address(0),0),typeSN,idPost,idUser,0,0);
        campaigns[idCampaign].proms[campaigns[idCampaign].nbProms++] = idProm;
        
        bytes32 idRequest = keccak256(abi.encodePacked(typeSN,idPost,idUser,now));
        results[idRequest] = Result(idProm,0,0,0);
        proms[idProm].results[0] = proms[idProm].prevResult = idRequest;
        proms[idProm].nbResults = 1;
        
         
        
        isAlreadyUsed[prom] = true;
        
        emit CampaignApplied(idCampaign,idProm);
        return idProm;
    }
    
    function validateProm(bytes32 idProm) public {
        Campaign storage cmp = campaigns[proms[idProm].idCampaign];
        require(cmp.endDate > now);
        require(cmp.advertiser == msg.sender);
        proms[idProm].isAccepted = true;
        cmp.nbValidProms++;
    }
    
    
    function startCampaign(bytes32 idCampaign) public  {
         require(campaigns[idCampaign].advertiser == msg.sender || msg.sender == owner );
         require(campaigns[idCampaign].startDate > now);
         campaigns[idCampaign].startDate = uint64(now);
    }
    
    function updateCampaignStats(bytes32 idCampaign) public onlyOwner {
        for(uint64 i = 0;i < campaigns[idCampaign].nbProms ;i++)
        {
            bytes32 idProm = campaigns[idCampaign].proms[i];
            if(proms[idProm].isAccepted) {
                bytes32 idRequest = keccak256(abi.encodePacked(proms[idProm].typeSN,proms[idProm].idPost,proms[idProm].idUser,now));
                results[idRequest] = Result(idProm,0,0,0);
                proms[idProm].results[proms[idProm].nbResults++] = idRequest;
                ask(proms[idProm].typeSN,proms[idProm].idPost,proms[idProm].idUser,idRequest);
            }
        }
    }
    
    function endCampaign(bytes32 idCampaign) public  {
        require(campaigns[idCampaign].endDate > now);
        require(campaigns[idCampaign].advertiser == msg.sender || msg.sender == owner );
        campaigns[idCampaign].endDate = uint64(now);
    }
    
    
    function ask(uint8 typeSN, string memory idPost,string memory idUser,bytes32 idRequest) public {
        IOracle o = IOracle(oracle);
        o.ask(typeSN,idPost,idUser,idRequest);
    }
    
    
    function update(bytes32 idRequest,uint64 likes,uint64 shares,uint64 views) external  returns (bool ok) {
        require(msg.sender == oracle);
       
        results[idRequest].likes = likes;
        results[idRequest].shares = shares;
        results[idRequest].views = views;
        promElement storage prom = proms[results[idRequest].idProm];
        uint256 gain = 0;
        
  
        gain = (likes - results[prom.prevResult].likes)* campaigns[prom.idCampaign].ratios[prom.typeSN].likeRatio;
        gain += (shares - results[prom.prevResult].shares)* campaigns[prom.idCampaign].ratios[prom.typeSN].shareRatio;
        gain += (views - results[prom.prevResult].views)* campaigns[prom.idCampaign].ratios[prom.typeSN].viewRatio;
        prom.prevResult = idRequest;
        
         
         
         
       
       
        if(prom.funds.token == address(0))
        {
            prom.funds.token = campaigns[prom.idCampaign].funds.token;
        }
        if(campaigns[prom.idCampaign].funds.amount <= gain )
        {
            campaigns[prom.idCampaign].endDate = uint64(now);
            prom.funds.amount += campaigns[prom.idCampaign].funds.amount;
            campaigns[prom.idCampaign].funds.amount = 0;
            emit CampaignFundsSpent(prom.idCampaign);
            return true;
        }
        campaigns[prom.idCampaign].funds.amount -= gain;
        prom.funds.amount += gain;
        return true;
    }
    
    function getGains(bytes32 idProm) public {
        require(proms[idProm].influencer == msg.sender);
        IERC20 erc20 = IERC20(proms[idProm].funds.token);
        uint256 amount = proms[idProm].funds.amount;
        proms[idProm].funds.amount = 0;
        erc20.transfer(proms[idProm].influencer,amount);
        
    }
    
    function getRemainingFunds(bytes32 idCampaign) public {
        require(campaigns[idCampaign].advertiser == msg.sender);
        require(campaigns[idCampaign].endDate < now);
        IERC20 erc20 = IERC20(campaigns[idCampaign].funds.token);
        uint256 amount = campaigns[idCampaign].funds.amount;
        campaigns[idCampaign].funds.amount = 0;
        erc20.transfer(campaigns[idCampaign].advertiser,amount);
    }
    
    function getProms (bytes32 idCampaign) public view returns (bytes32[] memory cproms)
    {
        uint nbProms = campaigns[idCampaign].nbProms;
        cproms = new bytes32[](nbProms);
        
        for (uint64 i = 0;i<nbProms;i++)
        {
            cproms[i] = campaigns[idCampaign].proms[i];
        }
        return cproms;
    }
    
    function getRatios (bytes32 idCampaign) public view returns (uint8[] memory types,uint256[] memory likeRatios,uint256[] memory shareRatios,uint256[] memory viewRatios )
    {   
        types = new uint8[](4);
        likeRatios = new uint256[](4);
        shareRatios = new uint256[](4);
        viewRatios = new uint256[](4);
        for (uint8 i = 0;i<4;i++)
        {
            types[i] = i+1;
            likeRatios[i] = campaigns[idCampaign].ratios[i+1].likeRatio;
            shareRatios[i] = campaigns[idCampaign].ratios[i+1].shareRatio;
            viewRatios[i] = campaigns[idCampaign].ratios[i+1].viewRatio;
        }
        return (types,likeRatios,shareRatios,viewRatios);
    }
    
    
    function getResults (bytes32 idProm) public view returns (bytes32[] memory creq)
    {
        uint nbResults = proms[idProm].nbResults;
        creq = new bytes32[](nbResults);
        for (uint64 i = 0;i<nbResults;i++)
        {
            creq[i] = proms[idProm].results[i];
        }
        return creq;
    }
    
    function getIsUsed(uint8 typeSN, string memory idPost, string memory idUser) public view returns (bool) {
        bytes32 prom = keccak256(abi.encodePacked(typeSN,idPost,idUser));
        return isAlreadyUsed[prom];
    }
    
    
}