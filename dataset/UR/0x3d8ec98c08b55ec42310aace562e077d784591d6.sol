 

pragma solidity ^0.5.0;

 



 
 

interface ERC20Token {

     
    function transfer(address _to, uint256 _value) external returns (bool success);

     
    function approve(address _spender, uint256 _value) external returns (bool success);

     
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

     
    function balanceOf(address _owner) external view returns (uint256 balance);

     
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

     
    function totalSupply() external view returns (uint256 supply);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Meritocracy {

    struct Status {
        address author;
        string praise;
        uint256 amount;
        uint256 time;  
    }

    struct Contributor {
        address addr;
        uint256 allocation;  
        uint256 totalForfeited;  
        uint256 totalReceived;
        uint256 received;  
         
        Status[] status;
    }

    ERC20Token public token;  
    address payable public owner;  
    uint256 public lastForfeit;  
    address[] public registry;  
    uint256 public maxContributors;  
    mapping(address => bool) public admins;
    mapping(address => Contributor) public contributors;

    Meritocracy public previousMeritocracy;  

     

    event ContributorAdded(address _contributor);
    event ContributorRemoved(address _contributor);
    event ContributorWithdrew(address _contributor);
    event ContributorTransaction(address _cSender, address _cReceiver);

    event AdminAdded(address _admin);
    event AdminRemoved(address _admin);
    event AllocationsForfeited();

    event OwnerChanged(address _owner);
    event TokenChanged(address _token);
    event MaxContributorsChanged(uint256 _maxContributors);
    event EscapeHatchTriggered(address _executor);


     

     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

     
    modifier onlyAdmin {
        require(admins[msg.sender]);
        _;
    }

     

     
    function allocate(uint256 _amount) external {
         
        
         
         
         
        uint256 individualAmount = _amount / registry.length;

         
        individualAmount = (individualAmount / 1000000000000000000 * 1000000000000000000);
        
        uint amount = individualAmount * registry.length;
        
        require(token.transferFrom(msg.sender, address(this), amount));
         
         
        for (uint256 i = 0; i < registry.length; i++) {
               contributors[registry[i]].allocation += individualAmount;
        }
    }

    function getRegistry() public view returns (address[] memory) {
        return registry;
    }

     

     
    function withdraw() external {
         
         Contributor storage cReceiver = contributors[msg.sender];
          
        require(cReceiver.addr == msg.sender);  
        require(cReceiver.received > 0);  
        require(cReceiver.allocation == 0);  
         
         
        uint256 r = cReceiver.received;
        cReceiver.received = 0;
         
        token.transfer(cReceiver.addr, r);
        emit ContributorWithdrew(cReceiver.addr);
    }

     
    function award(address _contributor, uint256 _amount,  string memory _praise) public {
         
        Contributor storage cSender = contributors[msg.sender];
        Contributor storage cReceiver = contributors[_contributor];
         
        require(_amount > 0);  
        require(cSender.addr == msg.sender);  
        require(cReceiver.addr == _contributor);
        require(cSender.addr != cReceiver.addr);  
        require(cSender.allocation >= _amount);  
         
        cSender.allocation -= _amount;  
        cReceiver.received += _amount;
        cReceiver.totalReceived += _amount;

        Status memory s = Status({
            author: cSender.addr,
            praise: _praise,
            amount: _amount,
            time: block.timestamp
        });

        cReceiver.status.push(s);  
        emit ContributorTransaction(cSender.addr, cReceiver.addr);
    }

    function getStatusLength(address _contributor) public view returns (uint) {
        return contributors[_contributor].status.length;
    }

    function getStatus(address _contributor, uint _index) public view returns (
        address author,
        string memory praise,
        uint256 amount,
        uint256 time
    ) {
        author = contributors[_contributor].status[_index].author;
        praise = contributors[_contributor].status[_index].praise;
        amount = contributors[_contributor].status[_index].amount;
        time = contributors[_contributor].status[_index].time;
    }

     
    function awardContributors(address[] calldata _contributors, uint256 _amountEach,  string calldata _praise) external {
         
        Contributor storage cSender = contributors[msg.sender];
        uint256 contributorsLength = _contributors.length;
        uint256 totalAmount = contributorsLength * _amountEach;
         
        require(cSender.allocation >= totalAmount);
         
        for (uint256 i = 0; i < contributorsLength; i++) {
                award(_contributors[i], _amountEach, _praise);
        }
    }

     

     
    function addContributor(address _contributor) public onlyAdmin {
         
        require(registry.length + 1 <= maxContributors);  
        require(contributors[_contributor].addr == address(0));  
         
        Contributor storage c = contributors[_contributor];
        c.addr = _contributor;
        registry.push(_contributor);
        emit ContributorAdded(_contributor);
    }

     
    function addContributors(address[] calldata _newContributors ) external onlyAdmin {
         
        uint256 newContributorLength = _newContributors.length;
         
        require(registry.length + newContributorLength <= maxContributors);  
         
        for (uint256 i = 0; i < newContributorLength; i++) {
                addContributor(_newContributors[i]);
        }
    }

     
     
     
    function removeContributor(uint256 idx) external onlyAdmin {  
         
        uint256 registryLength = registry.length - 1;
         
        require(idx < registryLength);  
         
        address c = registry[idx];
         
        registry[idx] = registry[registryLength];
        registry.pop();
        delete contributors[c];  
        emit ContributorRemoved(c);
    }

     
    function setMaxContributors(uint256 _maxContributors) external onlyAdmin {
        require(_maxContributors > registry.length);  
         
        maxContributors = _maxContributors;
        emit MaxContributorsChanged(maxContributors);
    }

     
    function forfeitAllocations() public onlyAdmin {
         
        uint256 registryLength = registry.length;
         
        require(block.timestamp >= lastForfeit + 1 weeks);  
         
        lastForfeit = block.timestamp; 
        for (uint256 i = 0; i < registryLength; i++) {  
                Contributor storage c = contributors[registry[i]];
                c.totalForfeited += c.allocation;  
                c.allocation = 0;
                 
        }
        emit AllocationsForfeited();
    }

     

     
    function addAdmin(address _admin) public onlyOwner {
        admins[_admin] = true;
        emit AdminAdded(_admin);
    }

     
    function removeAdmin(address _admin) public onlyOwner {
        delete admins[_admin];
        emit AdminRemoved(_admin);
    }

     
    function changeOwner(address payable _owner) external onlyOwner {
         
        removeAdmin(owner);
        addAdmin(_owner);
        owner = _owner;
        emit OwnerChanged(owner);
    }

     
     
    function changeToken(address _token) external onlyOwner {
         
         
        for (uint256 i = 0; i < registry.length; i++) {
                Contributor storage c = contributors[registry[i]];
                uint256 r =  c.received;
                c.received = 0;
                c.allocation = 0;
                 
                token.transfer(c.addr, r);  
        }
        lastForfeit = block.timestamp;
        token = ERC20Token(_token);
        emit TokenChanged(_token);
    }

     
    function escape() public onlyOwner {
         
        token.transfer(owner,  token.balanceOf(address(this)));
        owner.transfer(address(this).balance);
        emit EscapeHatchTriggered(msg.sender);
    }

     
     
    function escape(address _token) external onlyOwner {
         
        ERC20Token t = ERC20Token(_token);
        t.transfer(owner,  t.balanceOf(address(this)));
        escape();
    }

     

     
     
     
     
     

     

     
        
     

     
    constructor(address _token, uint256 _maxContributors) public {
         
        owner = msg.sender;
        addAdmin(owner);
        lastForfeit = block.timestamp;
        token = ERC20Token(_token);
        maxContributors= _maxContributors;
         
         
    }
}