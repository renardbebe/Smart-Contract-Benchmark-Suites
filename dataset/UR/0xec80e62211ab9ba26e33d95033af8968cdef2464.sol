 

contract TadamWhitelistPublicSale{
    
    mapping (address => bool) private owner;
    mapping (address => bool) public canWhiteList;
    mapping (address => uint) public PublicSaleWhiteListed; 
    
    function TadamWhitelistPublicSale(){
        owner[msg.sender] = true;
    }
    event eWhitelisted(address _addr, uint _group);
    

    function Whitelist(address _addr, uint _group) public{
         
        require( (canWhiteList[msg.sender]) && (_group >=0 && _group <= 2) );
        PublicSaleWhiteListed[_addr] = _group;
    }
    
    function addWhiteLister(address _address) public onlyOwner {
        canWhiteList[_address] = true;
    }
    
    function removeWhiteLister(address _address) public onlyOwner {
        canWhiteList[_address] = false;
    }
    
    function isWhiteListed(address _addr) returns (uint _group){
        var group = PublicSaleWhiteListed[_addr];
        eWhitelisted(_addr, group);
        return group;
    }

    
    modifier onlyOwner(){
        require(owner[msg.sender]);
        _;
    }
    
}