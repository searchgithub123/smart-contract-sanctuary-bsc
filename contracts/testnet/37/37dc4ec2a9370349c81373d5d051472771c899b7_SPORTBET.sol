/**
 *Submitted for verification at BscScan.com on 2022-12-02
*/

//SPDX-License-Identifier: MIT License
pragma solidity ^0.8.17;

interface Itoken {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 retue);

    event Approve(
        address indexed owner,
        address indexed spender,
        uint256 retue
    );
}

contract SPORTBET {
    address public Admin;
    address public House_Wallet;
    Itoken public token;
    uint256 public min_bet;

    //distribution criteria
    uint256 public house_percent = 20;
    uint256 public prize_percent = 70;
    uint256 public refferal_prize_percent = 10;
    uint256 public refferal_bet_percent = 3;
    uint256 public divider = 100;

    //games variables
    string[] public games;
    mapping(uint256 => games_data) public GamesData;
    mapping(address => players_data) public players;

    mapping(address => uint256) winners;

    struct players_data {
        address player_address;
        uint256 betted;
        uint256 balance;
        uint256 toclaim;
        uint256 claimed;
        uint256 gains;
        uint256 losts;
    }

    struct bet_possibilitys {
        uint256 team1;
        uint256 team2;
        uint256 drawgame;
    } 

    struct games_data {
        bool status;
        uint256 gameid;
        string team1;
        string team2;
        string drawgame;
        uint256 bteam1;
        uint256 bteam2;
        uint256 bdrawgame;
        mapping(address => bet_possibilitys) participants;
        mapping(address => bool) hasparticipated;
        address[] uniqueaddress;
        uint256 end_time;
        uint256 top_prize;
        uint256 ref_prizes;
        string result;
    }

    struct refplayer {
        uint256 referenced;
        uint256 claimed;
        uint256 toClaim;
        uint256 fromPrize;
        uint256 fromBets;
    }

    mapping(address => refplayer) public refferal_part;
    mapping(address => address) public reffral;

    event gameAdded(uint256 _gameId, uint256 _endDeadline);
    event betting(uint256 _gameId, uint256 amount, address _better);
    event endingGame(uint256 _gameId, uint256 _topPrize, uint256 _refPrizes);
    event userWithdraw(address _user, uint256 _amount);
    event userDeposit(address _user, uint256 _amount);


    modifier onlyAdmin() {
        require(msg.sender == Admin);
        _;
    }

    constructor() {
        Admin = 0xabc4B357D7419cfD3747DC1338e9e6308612D87c;
        House_Wallet = 0x42A20C445E2442cd54fa6199c0069b182bd0B6e2;
        token = Itoken(0xcdE642b47dB090b70dD25f3D7B35A247DEe4b412); //token
        min_bet = 1 * (10**token.decimals());
    }

    function addGame(string memory _gameName, string memory _team1, string memory _team2, uint256 _betDeadline) external onlyAdmin {
        games.push(_gameName);
        string memory draw = "DRAW";
        GamesData[(games.length - 1)].gameid = (games.length - 1);
        GamesData[(games.length - 1)].status = true;
        GamesData[(games.length - 1)].team1 = _team1;
        GamesData[(games.length - 1)].team2 = _team2;
        GamesData[(games.length - 1)].drawgame = draw;
        GamesData[(games.length - 1)].end_time = block.timestamp + _betDeadline;

        emit gameAdded((games.length - 1), GamesData[(games.length - 1)].end_time);
    }

    function endGame(uint256 _gameId, uint256 _winner) external onlyAdmin {
        require(block.timestamp > GamesData[_gameId].end_time, "Not time to do that");

        uint256 prize;
        uint256 house;
        uint256 ref_topPrize;
        uint256 prizeDivider;
        GamesData[_gameId].status = false;
        if(_winner == 0){
            prize = ((GamesData[_gameId].bteam2 + GamesData[_gameId].bdrawgame) * prize_percent) / divider;
            house = ((GamesData[_gameId].bteam2 + GamesData[_gameId].bdrawgame) * house_percent) / divider;
            ref_topPrize = ((GamesData[_gameId].bteam2 + GamesData[_gameId].bdrawgame) * refferal_prize_percent) / divider;
            GamesData[_gameId].result = GamesData[_gameId].team1;
            prizeDivider = GamesData[_gameId].bteam1;
        }
        if(_winner == 1){
            prize = ((GamesData[_gameId].bteam1 + GamesData[_gameId].bdrawgame) * prize_percent) / divider;
            house = ((GamesData[_gameId].bteam1 + GamesData[_gameId].bdrawgame) * house_percent) / divider;
            ref_topPrize = ((GamesData[_gameId].bteam1 + GamesData[_gameId].bdrawgame) * refferal_prize_percent) / divider;
            GamesData[_gameId].result = GamesData[_gameId].team2;
            prizeDivider = GamesData[_gameId].bteam2;
        }
        if(_winner == 2){
            prize = ((GamesData[_gameId].bteam2 + GamesData[_gameId].bteam1) * prize_percent) / divider;
            house = ((GamesData[_gameId].bteam2 + GamesData[_gameId].bteam1) * house_percent) / divider;
            ref_topPrize = ((GamesData[_gameId].bteam2 + GamesData[_gameId].bteam1) * house_percent) / divider;
            GamesData[_gameId].result = GamesData[_gameId].drawgame;
            prizeDivider = GamesData[_gameId].bdrawgame;
        }
        
        players_data storage user;
        uint256 touser = 0;
        uint256 toref = 0;
        for(uint256 i = 0; i < GamesData[_gameId].uniqueaddress.length; i++){
            user = players[GamesData[_gameId].uniqueaddress[i]];
            if(_winner == 0){
                if(GamesData[_gameId].participants[GamesData[_gameId].uniqueaddress[i]].team1 > 0){
                    touser = prize * (GamesData[_gameId].participants[GamesData[_gameId].uniqueaddress[i]].team1 / prizeDivider);
                    
                    if(reffral[msg.sender] != address(0)){
                        toref = (touser * refferal_prize_percent) / divider;
                        players[reffral[msg.sender]].toclaim += toref;
                        refferal_part[reffral[msg.sender]].fromPrize += toref;
                    }
                    user.gains += touser;
                    touser = touser + (GamesData[_gameId].participants[GamesData[_gameId].uniqueaddress[i]].team1 * refferal_bet_percent) / divider;
                    user.toclaim += touser + GamesData[_gameId].participants[GamesData[_gameId].uniqueaddress[i]].team1;
                }
                user.losts += GamesData[_gameId].participants[GamesData[_gameId].uniqueaddress[i]].team2;
                user.losts += GamesData[_gameId].participants[GamesData[_gameId].uniqueaddress[i]].drawgame;
            }
            if(_winner == 1){
                if(GamesData[_gameId].participants[GamesData[_gameId].uniqueaddress[i]].team2 > 0){
                    touser = prize * (GamesData[_gameId].participants[GamesData[_gameId].uniqueaddress[i]].team2 / prizeDivider);
                    if(reffral[msg.sender] != address(0)){
                        toref = (touser * refferal_prize_percent) / divider;
                        players[reffral[msg.sender]].toclaim += toref;
                        refferal_part[reffral[msg.sender]].fromPrize += toref;
                    }
                    user.gains += touser;
                    touser = touser + (GamesData[_gameId].participants[GamesData[_gameId].uniqueaddress[i]].team2 * refferal_bet_percent) / divider;
                    user.toclaim += touser + GamesData[_gameId].participants[GamesData[_gameId].uniqueaddress[i]].team2;
                }
                user.losts += GamesData[_gameId].participants[GamesData[_gameId].uniqueaddress[i]].team1;
                user.losts += GamesData[_gameId].participants[GamesData[_gameId].uniqueaddress[i]].drawgame;
            }
            if(_winner == 2){
                if(GamesData[_gameId].participants[GamesData[_gameId].uniqueaddress[i]].drawgame > 0){
                    touser = prize * (GamesData[_gameId].participants[GamesData[_gameId].uniqueaddress[i]].drawgame / prizeDivider);
                    if(reffral[msg.sender] != address(0)){
                        toref = (touser * refferal_prize_percent) / divider;
                        players[reffral[msg.sender]].toclaim += toref;
                        refferal_part[reffral[msg.sender]].fromPrize += toref;
                    }
                    user.gains += touser;
                    touser = touser + (GamesData[_gameId].participants[GamesData[_gameId].uniqueaddress[i]].drawgame * refferal_bet_percent) / divider;
                    user.toclaim += touser + GamesData[_gameId].participants[GamesData[_gameId].uniqueaddress[i]].drawgame;
                }
                user.losts += GamesData[_gameId].participants[GamesData[_gameId].uniqueaddress[i]].team2;
                user.losts += GamesData[_gameId].participants[GamesData[_gameId].uniqueaddress[i]].team1;
            }
        }
        GamesData[_gameId].top_prize = prize;
        GamesData[_gameId].ref_prizes = (prize * refferal_prize_percent) / divider;
        players[House_Wallet].toclaim += house;
        players[House_Wallet].gains += house;
        emit endingGame(_gameId, prize, GamesData[_gameId].ref_prizes);
    }

    function betOnGame(uint256 _gameId, uint256 _team, uint256 _bet, address _ref) external {
        require(block.timestamp < GamesData[_gameId].end_time, "Not time to do that");
        require(_team < 3, "Only 3 ways!");
        require(_bet > min_bet, "Bet below min bet amount!");
        require(_ref != msg.sender, "You can't ref yourself!");

        if(reffral[msg.sender] == address(0)){
            if(_ref != address(0)){
                reffral[msg.sender] = _ref;
                refferal_part[_ref].referenced++;
            }
        }

        players[msg.sender].player_address = msg.sender;
        
        
        if(_bet < players[msg.sender].balance){
            players[msg.sender].balance -= _bet;
        }else{
            uint256 amountFromWallet = _bet - players[msg.sender].balance;
            token.transferFrom(msg.sender, address(this), amountFromWallet);
            players[msg.sender].balance = 0;
        }
        uint256 originalBet = _bet;
        uint256 ref_bet_amount = (_bet * refferal_bet_percent) / divider;

        players[msg.sender].betted += _bet;
        
        if(reffral[msg.sender] != address(0)){
            //pagamento do refereal da aposta 3%
            _bet -= ref_bet_amount;
            players[reffral[msg.sender]].toclaim += ref_bet_amount;
            refferal_part[reffral[msg.sender]].fromBets += ref_bet_amount;
        }

        if(_team == 0){
            GamesData[_gameId].participants[msg.sender].team1 += _bet;
            GamesData[_gameId].bteam1 += _bet;
        }
        if(_team == 1){
            GamesData[_gameId].participants[msg.sender].team2 += _bet;
            GamesData[_gameId].bteam2 += _bet;
        }
        if(_team == 2){
            GamesData[_gameId].participants[msg.sender].drawgame += _bet;
            GamesData[_gameId].bdrawgame += _bet;
        }
        
        if (!GamesData[_gameId].hasparticipated[msg.sender]) {
            GamesData[_gameId].uniqueaddress.push(msg.sender);
            GamesData[_gameId].hasparticipated[msg.sender] = true;
        }

        emit betting(_gameId, originalBet, msg.sender);
        
    }

    function withdraw(uint256 _amount) external {
        require(_amount > 0, "Amount cannot be 0");
        require(token.balanceOf(address(this)) > _amount, "Error, sorry :-(");
        require(players[msg.sender].balance >= _amount, "Amount cannot be greater than your balance");
        token.transfer(msg.sender, _amount);
        players[msg.sender].balance -= _amount;

        emit userWithdraw(msg.sender, _amount);

    }

    function claimPrize() external {
        require(players[msg.sender].toclaim > 0, "Nothing to claim!");

        players[msg.sender].balance += players[msg.sender].toclaim;
        players[msg.sender].claimed += players[msg.sender].toclaim;
        players[msg.sender].toclaim = 0;

    }

    function deposit(uint256 _amount) external {
        token.transferFrom(msg.sender, address(this), _amount);
        players[msg.sender].balance += _amount;

        emit userDeposit(msg.sender, _amount);
    }

    function set_token(Itoken _token) external onlyAdmin {
        require(address(_token) != address(0));
        token = _token;
    }

    function set_min_bet(uint256 _min_bet) external onlyAdmin {
        require(_min_bet > 0);
        min_bet = _min_bet;
    }

    function set_admin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0));
        Admin = newAdmin;
    }


    function set_house_wallet(address newHouse_Wallet)
        external
        onlyAdmin
    {
        require(newHouse_Wallet != address(0));
        House_Wallet = newHouse_Wallet;
    }

    function get_contract_balance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function withdraw_stuck_token(Itoken _token, uint256 stuck_amount)
        external
        onlyAdmin
    {
        require(address(_token) != address(0));
        require(
            stuck_amount > 0 && stuck_amount <= token.balanceOf(address(this))
        );
        _token.transfer(msg.sender, stuck_amount);
    }

    function set_prize_percentage(uint256 _prize_percentage)
        external
        onlyAdmin
    {
        require(_prize_percentage > 0);
        prize_percent = _prize_percentage;
    }

    function set_house_percent(uint256 _house_percentage)
        external
        onlyAdmin
    {
        require(_house_percentage > 0);
        house_percent = _house_percentage;
    }

}