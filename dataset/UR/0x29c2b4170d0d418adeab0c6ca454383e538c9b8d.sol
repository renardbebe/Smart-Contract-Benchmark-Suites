 

pragma solidity 0.4.19;


contract InterfaceRandao {
    function getRandom(uint256 _campaignID) external returns (uint256);
}


contract InterfaceWallet {
    function changeState(uint256 _id, uint8 _state) public returns (bool);
    function changeBranch(uint256 _id, uint8 _branch) public returns (bool);
    function getHolder(uint256 _id) public view returns (address);
}


contract EpisodeManager {
    address public owner;
    address public wallet;

     
    uint256 public cap = 50;

    address public randaoAddress;
    address public lotteryAddress;
    InterfaceWallet public lottery = InterfaceWallet(0x0);
    InterfaceRandao public randao = InterfaceRandao(0x0);

    bool public started = false;

    uint256 public episodesNum = 0;

     
    struct CommandAndRandom {
        uint256 random;
        string command;
        bool isSet;
    }

     
    struct BranchAndCost {
        uint256 price;
        bool isBranch;
    }

    struct Episode {
         
        mapping (uint256 => mapping(uint256 => CommandAndRandom)) data;
         
        mapping (uint256 => BranchAndCost) branches;
        bool isEpisode;
    }

    mapping (uint256 => Episode) public episodes;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function EpisodeManager(address _randao, address _wallet) public {
        require(_randao != address(0));
        require(_wallet != address(0));
        owner = msg.sender;
        wallet = _wallet;
        randaoAddress = _randao;
        randao = InterfaceRandao(_randao);
    }

    function setLottery(address _lottery) public {
        require(!started);
        lotteryAddress = _lottery;
        lottery = InterfaceWallet(_lottery);
        started = true;
    }

    function changeRandao(address _randao) public onlyOwner {
        randaoAddress = _randao;
        randao = InterfaceRandao(_randao);
    }

    function addEpisode() public onlyOwner returns (bool) {
        episodesNum++;
        episodes[episodesNum].isEpisode = true;

        return true;
    }

    function addEpisodeData(
        uint256 _branch,
        uint256 _step,
        uint256 _campaignID,
        string _command) public onlyOwner returns (bool)
    {
        require(_branch > 0);
        require(_step > 0);
        require(_campaignID > 0);
        require(episodes[episodesNum].isEpisode);
        require(!episodes[episodesNum].data[_branch][_step].isSet);

        episodes[episodesNum].data[_branch][_step].random = randao.getRandom(_campaignID);

        episodes[episodesNum].data[_branch][_step].command = _command;
        episodes[episodesNum].data[_branch][_step].isSet = true;

        return true;
    }

    function addNewBranchInEpisode(uint256 _branch, uint256 _price) public onlyOwner returns (bool) {
        require(_branch > 0);
        require(!episodes[episodesNum].branches[_branch].isBranch);
        episodes[episodesNum].branches[_branch].price = _price;
        episodes[episodesNum].branches[_branch].isBranch = true;
        return true;
    }

    function changeBranch(uint256 _id, uint8 _branch) public payable returns(bool) {
        require(_branch > 0);
        require(episodes[episodesNum].branches[_branch].isBranch);
        require((msg.sender == lottery.getHolder(_id)) || (msg.sender == owner));

        if (episodes[episodesNum].branches[_branch].price == 0) {
            lottery.changeBranch(_id, _branch);
        } else {
            require(msg.value == episodes[episodesNum].branches[_branch].price);
            lottery.changeBranch(_id, _branch);
            forwardFunds();
        }
        return true;
    }

    function changeState(uint256 _id, uint8 _state) public onlyOwner returns (bool) {
        require(_id > 0 && _id <= cap);
        require(_state <= 1);
        return lottery.changeState(_id, _state);
    }

    function getEpisodeDataRandom(uint256 _episodeID, uint256 _branch, uint256 _step) public view returns (uint256) {
        return episodes[_episodeID].data[_branch][_step].random;
    }

    function getEpisodeDataCommand(uint256 _episodeID, uint256 _branch, uint256 _step) public view returns (string) {
        return episodes[_episodeID].data[_branch][_step].command;
    }

    function getEpisodeBranchData(uint256 _episodeID, uint256 _branch) public view returns (uint256) {
        return episodes[_episodeID].branches[_branch].price;
    }

     
     
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }
}