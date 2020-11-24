 

pragma solidity 0.5.11;

 
contract RaffleMarket {
     

     

     
    event OnBuyRaffleTickets(
        uint256 indexed _raffleId,
        address indexed _ticketHolder,
        uint256 _tickets
    );

     
    event OnCancelRaffle(
        uint256 indexed _raffleId,
        address indexed _host
    );

     
    event OnCreateRaffle(
        uint256 indexed _raffleId,
        uint256 indexed _tokenId,
        address indexed _host,
        uint256 _costPerTicket,
        uint256 _minimumTickets
    );

     
    event OnDeleteTickets(
        uint256 indexed _expiredRaffleId,
        uint256 _tickets
    );

     
    event OnRaffleWinner(
        uint256 indexed _raffleId,
        address indexed _winner,
        uint256 _random,
        uint256 _payout,
        uint256 _contribution
    );

     
    event OnRefundTickets(
        uint256 _raffleId,
        uint256 _quantity
    );

     
    event OnRemoveAdmin(
        address _admin
    );

     
    event OnSetAdmin(
        address _admin
    );

     
    event OnSetMinimumCostPerTicket(
        uint256 _minimumCostPerTicket
    );

     
    event OnSetTokenAddress(
        address _tokenAddress
    );

     
    event OnSetTreasury(
        address _treasury
    );

     
    event OnSetContributionPercent(
        uint256 _contributionPercent
    );

     
    event OnWithdrawRaffleTickets(
        uint256 indexed _raffleId,
        address indexed _ticketHolder,
        uint256[] _indexes
    );

     
    struct Raffle {
        uint256 tokenId;
        address host;
        uint256 costPerTicket;
        uint256 minimumTickets;
        address payable[] participants;
    }

     

     
    mapping(uint256 => Raffle) public raffles;

     
    uint256 public contributionPercent;

     
    uint256 public minRaffleTicketCost;

     
    address public tokenAddress;

     
    interfaceERC721 public tokenInterface;

     
    uint256 public totalRaffles;

     

     
    mapping(address => bool) private admin;

     
    address payable private treasury;

     

     
    constructor(uint256 _contributionPercent, uint256 _minRaffleTicketCost, address _tokenAddress, address payable _treasury)
        public
    {
        admin[msg.sender] = true;
        tokenInterface = interfaceERC721(_tokenAddress);
        setAdmin(msg.sender);
        setContributionPercent(_contributionPercent);
        setMinRaffleTicketCost(_minRaffleTicketCost);
        setTokenAddress(_tokenAddress);
        setTreasury(_treasury);
    }

     

     
    modifier onlyAdmin() {
        require(admin[msg.sender], "only admins");
        _;
    }

     
    modifier onlyEOA() {
        require(msg.sender == tx.origin, "only externally owned accounts");
        _;
    }

     

     
    function activateRaffle(uint256 raffleId)
        public
        onlyEOA
    {
         
        Raffle storage raffle = raffles[raffleId];

         
        require(raffle.participants.length >= raffle.minimumTickets, "requires minimum number of tickets");

        selectWinningTicket(raffleId);
    }

     
    function activateRaffleAsHost(uint256 raffleId)
        public
        onlyEOA
    {
         
        Raffle storage raffle = raffles[raffleId];

         
        require(raffle.host == msg.sender, "only the raffle host can activate");

         
        require(raffle.participants.length >= 1, "at least one participant needed to raffle");

        selectWinningTicket(raffleId);
    }

     
    function buyRaffleTickets(uint256 raffleId)
        public
        payable
        onlyEOA
    {
         
        Raffle storage raffle = raffles[raffleId];

         
        require(raffle.host != address(0), "invalid raffle");

         
        require(msg.value >= raffle.costPerTicket, "must send enough ETH for at least 1 ticket");

         
        uint256 tickets = msg.value / raffle.costPerTicket;

         
        uint256 remainder = msg.value % raffle.costPerTicket;

         
        for (uint256 i = 0; i < tickets; i++) {
            raffle.participants.push(msg.sender);
        }

         
        if (remainder > 0) {
            msg.sender.transfer(remainder);
        }

        emit OnBuyRaffleTickets(raffleId, msg.sender, tickets);
    }

     
    function cancelRaffle(uint256 raffleId)
        public
    {
         
        Raffle storage raffle = raffles[raffleId];

         
        require(raffle.host == msg.sender, "raffle host only");

         
        require(raffle.participants.length == 0, "must be no participants in attendance");

         
        uint256 tokenId = raffle.tokenId;

         
        deleteRaffle(raffleId);

         
        tokenInterface.transferFrom(address(this), msg.sender, tokenId);

        emit OnCancelRaffle(raffleId, msg.sender);
    }

     
    function deleteAndBuyRaffleTickets(uint256 expiredRaffleId, uint256 tickets, uint256 raffleId)
        public
        payable
    {
         
        Raffle storage raffle = raffles[expiredRaffleId];

         
        require(raffle.host == address(0), "raffle expired");

         
        if (raffle.participants.length > tickets) {
            do {
                raffle.participants.pop();
            }
            while (raffle.participants.length < raffle.participants.length - tickets);
            emit OnDeleteTickets(expiredRaffleId, tickets);
        } else if (raffle.participants.length > 0) {
            do {
                raffle.participants.pop();
            }
            while (raffle.participants.length > 0);
            emit OnDeleteTickets(expiredRaffleId, raffle.participants.length);
        }

        buyRaffleTickets(raffleId);
    }

     
    function withdrawRaffleTickets(uint256 raffleId, uint256[] memory indexes)
        public
    {
         
        Raffle storage raffle = raffles[raffleId];

         
        require(raffle.host != address(0), "invalid raffle");

         
        require(indexes.length > 0, "must be greater than 0");

         
        for(uint256 i = 0; i < indexes.length; i++) {
             
            require(raffle.participants[indexes[i]] == msg.sender, "must be ticket owner");

             
            if (i > 0) {
                require(indexes[i] < indexes[i - 1], "must be sorted from highest index to lowest index");
            }

             
            raffle.participants[indexes[i]] = raffle.participants[raffle.participants.length - 1];

             
            raffle.participants.pop();
        }

        emit OnWithdrawRaffleTickets(raffleId, msg.sender, indexes);

         
        msg.sender.transfer(indexes.length * raffle.costPerTicket);
    }

     
    function refundRaffleTickets(uint256 raffleId, uint256 quantity)
        public
    {
         
        Raffle storage raffle = raffles[raffleId];

         
        require(raffle.host == msg.sender, "must be raffle host");

         
        require(quantity > 0, "must refund at least one ticket");

         
        require(raffle.participants.length > 0, "must have participants to refund");

         
        uint256 numberOfTicketsToRefund = quantity;

         
        if (quantity > raffle.participants.length) {
            numberOfTicketsToRefund = raffle.participants.length;
        }

         
        for(uint256 i = 0; i < numberOfTicketsToRefund; i++) {
             
            address payable participant = raffle.participants[raffle.participants.length - 1];

             
            raffle.participants.pop();

             
            participant.transfer(raffle.costPerTicket);
        }

        emit OnRefundTickets(raffleId, quantity);
    }

     

     
    function getRaffle(uint256 raffleId)
        public
        view
        returns(uint256 _tokenId, address _host, uint256 _costPerTicket, uint256 _minimumTickets, uint256 _participants)
    {
        Raffle storage raffle = raffles[raffleId];

        _tokenId = raffle.tokenId;
        _host = raffle.host;
        _costPerTicket = raffle.costPerTicket;
        _minimumTickets = raffle.minimumTickets;
        _participants = raffle.participants.length;
    }

     
    function getRaffles(uint256[] memory raffleIds)
        public
        view
        returns(uint256[] memory _tokenId, address[] memory _host, uint256[] memory _costPerTicket, uint256[] memory _minimumTickets, uint256[] memory _participants)
    {
        for(uint256 i = 0; i < raffleIds.length; i++) {
            Raffle storage raffle = raffles[raffleIds[i]];

            _tokenId[i] = raffle.tokenId;
            _host[i] = raffle.host;
            _costPerTicket[i] = raffle.costPerTicket;
            _minimumTickets[i] = raffle.minimumTickets;
            _participants[i] = raffle.participants.length;
        }
    }

     

     
    function setContributionPercent(uint256 _contributionPercent)
        public
        onlyAdmin
    {
        require(_contributionPercent < 500, "Can not exceed 50%");
        contributionPercent = _contributionPercent;

        emit OnSetContributionPercent(_contributionPercent);
    }

     
    function setMinRaffleTicketCost(uint256 _minRaffleTicketCost)
        public
        onlyAdmin
    {
        minRaffleTicketCost = _minRaffleTicketCost;

        emit OnSetMinimumCostPerTicket(_minRaffleTicketCost);
    }

     
    function setAdmin(address _admin)
        public
        onlyAdmin
    {
        admin[_admin] = true;

        emit OnSetAdmin(_admin);
    }

     
    function removeAdmin(address _admin)
        public
        onlyAdmin
    {
        require(msg.sender != _admin, "self deletion not allowed");
        delete admin[_admin];

        emit OnRemoveAdmin(_admin);
    }

     
    function setTreasury(address payable _treasury)
        public
        onlyAdmin
    {
        treasury = _treasury;

        emit OnSetTreasury(_treasury);
    }

     

     
    function onERC721Received(address  , address _from, uint256 _tokenId, bytes calldata _data)
        external
        returns(bytes4)
    {
         
        require(msg.sender == tokenAddress, "must be the token address");

         
        require(tx.origin == _from, "token owner must be an externally owned account");

         
        (uint256 costPerTicket, uint256 minimumTickets) = abi.decode(_data, (uint256, uint256));

         
        createRaffle(_tokenId, _from, costPerTicket, minimumTickets);

         
        return 0x150b7a02;
    }

     

     
    function createRaffle(uint256 tokenId, address host, uint256 costPerTicket, uint256 minimumTickets)
        private
    {
         
        require(costPerTicket >= minRaffleTicketCost, "ticket price must meet the minimum");

         
        require(minimumTickets > 0, "must set at least one raffle ticket");

         
        totalRaffles = totalRaffles + 1;
        uint256 raffleId = totalRaffles;

         
        raffles[raffleId] = Raffle({
            tokenId: tokenId,
            host: host,
            costPerTicket: costPerTicket,
            minimumTickets: minimumTickets,
            participants: new address payable[](0)
        });

         
        emit OnCreateRaffle(raffleId, tokenId, host, costPerTicket, minimumTickets);
    }

     
    function deleteRaffle(uint256 raffleId)
        private
    {
         
        delete raffles[raffleId].tokenId;
        delete raffles[raffleId].host;
        delete raffles[raffleId].costPerTicket;
        delete raffles[raffleId].minimumTickets;
    }

     
    function selectWinningTicket(uint256 raffleId)
        private
    {
         
        Raffle storage raffle = raffles[raffleId];

         
        (uint256 random) = getRandom(raffle.participants.length);

         
        address winner = raffle.participants[random];

         
        assert(winner != address(0));

         
        uint256 pot = raffle.participants.length * raffle.costPerTicket;

         
        uint256 contribution = (pot * contributionPercent) / 1000;

         
        uint256 payout = pot - contribution;

         
        address payable host = address(uint160(raffle.host));

         
        uint256 tokenId = raffle.tokenId;

         
        deleteRaffle(raffleId);

         
        interfaceERC721(tokenAddress).transferFrom(address(this), winner, tokenId);

         
        assert(tokenInterface.ownerOf(tokenId) == winner);

         
        treasury.transfer(contribution);

         
        host.transfer(payout);

        emit OnRaffleWinner(raffleId, winner, random, payout, contribution);
    }

     
    function getRandom(uint256 max)
        private
        view
        returns(uint256 random)
    {
         
        uint256 blockhash_ = uint256(blockhash(block.number - 1));

         
        uint256 balance = address(this).balance;

         
        random = uint256(keccak256(abi.encodePacked(
             
            block.timestamp,
             
            block.coinbase,
             
            block.difficulty,
             
            blockhash_,
             
            balance
        ))) % max;
    }

     
    function setTokenAddress(address _tokenAddress)
        private
    {
        tokenAddress = _tokenAddress;
        emit OnSetTokenAddress(_tokenAddress);
    }
}

 
 
contract interfaceERC721 {
    function transferFrom(address from, address to, uint256 tokenId) public;
    function ownerOf(uint256 tokenId) public view returns (address);
}