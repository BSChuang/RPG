// firebase deploy --only functions:[function]

const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp(functions.config().firebase);
const db = admin.firestore()
db.settings({
    timestampsInSnapshots: true
});

exports.buildAdventure = functions.firestore.document('players/{uid}').onUpdate((change, context) => {
    var aftData = change.after.data();
    var mission = 'mission 1';

    // Check if player is leader and if all players have readied
    var ready = true;
    var readyPromises = [];
    var leader;
    Object.keys(aftData['party']).forEach(pUid => {
        readyPromises.push(checkReady(pUid));
    })

    function checkReady(pUid) {
        return db.collection('players').doc(pUid).get().then(pSnap => {
            var pData = pSnap.data();
            if (pData['ready'] == false) {
                ready = false;
            }

            if (aftData['party'][pUid] == true) {
                leader = pUid
            }
        })
    }

    return Promise.all(readyPromises).then(() => {
        if (!ready) {
            return null;
        }

        return db.collection('players').doc(leader).get().then(leaderSnap => {
            var leaderData = leaderSnap.data();

            var party = Object.keys(leaderData['party']);

            if (leaderData['currentAdventure'] == "") { // If not currently in adventure
                var adventureID = db.collection('adventures').doc().id;
                var battleID = db.collection('battles').doc().id;

                return db.collection('adventures').doc(adventureID).create({ // Create adventure
                    'party': party,
                    'currentBattle': battleID,
                    'currentPhase': 0,
                    'mission': mission
                }).then(() => { // Get adventure data
                    return db.collection('adventure builder').doc(mission).get().then(missionSnap => {
                        var missionData = missionSnap.data();
                        battle = missionData['phases'][0]; // Phase 0 data (map)

                        return db.collection('battles').doc(battleID).create({ // Create first battle
                            'battleBuilder': battle,
                            'adventure': adventureID,
                            'party': party
                        })
                    });
                }).then(() => { // Set all adventure id's of players to this adventure id.
                    var adventurePromises = [];

                    party.forEach(uid => {
                        adventurePromises.push(updateAdventure(uid));
                    })

                    return Promise.all(adventurePromises);

                    function updateAdventure(uid) {
                        return db.collection('players').doc(uid).update({
                            'currentAdventure': adventureID
                        })
                    }
                })
            }
        })
    })
})

// If a new battle was created, take the battleBuilder and turn it into an actual battle
exports.buildBattle = functions.firestore.document('battles/{battleID}').onCreate((snap, context) => {
    var battleID = context.params.battleID;
    var data = snap.data()
    var bb = data['battleBuilder'];

    var enemiesDict = bb['enemies'];
    Object.keys(enemiesDict).forEach(enemy => {
        enemiesDict[enemy]
    })

    var constitutionMult = 10;
    var stats = ['charisma', 'constitution', 'dexterity', 'intelligence', 'strength', 'wisdom']

    var orderDict = {}

    var battleRef = db.collection('battles').doc(battleID);

    var level = 1; // CHANGE THIS
    var players = data['party'];

    /* if (aftData['battle']['type'] == 'random') {
        var _enemyTypes = ['Giant Zombie']
        var _enemyCount = Math.ceil(Math.random() * 3);
        for (var i = 0; i < _enemyCount; i++) {
            enemies.push(_enemyTypes[Math.floor(Math.random() * _enemyTypes.length)]);
        }
    } */

    var playerPromises = [];
    players.forEach(player => {
        playerPromises.push(addPlayer(player));
    })

    function addPlayer(uid) {
        var playerRef = db.collection('players').doc(uid);
        return playerRef.get().then((snap) => {
            var playerData = snap.data();
            var hp = playerData['stats']['constitution'] * constitutionMult;

            var slots = ['head', 'torso', 'legs', 'hands', 'feet']
            var resistances = {
                'air': 0,
                'bludgeon': 0,
                'earth': 0,
                'fire': 0,
                'pierce': 0,
                'slash': 0,
                'water': 0
            };
            var equip = {}
            var skillSlots = ['skill1', 'skill2', 'skill3', 'skill4']
            var skills = {}
            var armor = 0

            var promises = []
            slots.forEach(slot => {
                promises.push(getArmor(slot))
            })
            skillSlots.forEach(slot => {
                promises.push(getSkill(slot))
            })


            return Promise.all(promises).then(() => {
                orderDict[uid] = playerData['stats']['dexterity']

                // Weapon
                var weaponID = playerData['equipment']['weapon']
                var critChance = 0
                var critDamage = 0
                var damage = 0
                return playerRef.collection('inventory').doc(weaponID).get().then(weaponSnap => {
                    var weaponData = weaponSnap.data()
                    var weaponLvl = weaponData['lvl']
                    var weaponName = weaponData['name']

                    return db.collection('equipment').doc(weaponName).get().then(itemSnap => {
                        var lvlMult = 0.5
                        var itemData = itemSnap.data();
                        var itemStat = itemData['stat']
                        critChance = itemData['critChance']
                        critDamage = itemData['critDamage']

                        damage = (itemData['damage'] + playerData['stats'][itemStat]) * ((lvlMult * weaponLvl) + 1)
                    })
                }).then(() => {
                    return battleRef.collection('allies').doc(uid).set({
                        'equipment': equip,
                        'skills': skills,
                        'name': playerData['name'],
                        'stats': playerData['stats'],
                        'hp': hp,
                        'maxHP': hp,
                        'armor': armor,
                        'maxArmor': armor,
                        'critChance': critChance,
                        'critDamage': critDamage,
                        'damage': damage,
                        'resistances': resistances,
                        'effects': {
                            'dot': [],
                            'status': []
                        },
                        'anim': playerData['anim']
                    })
                })
            }).then(() => {
                return playerRef.update({
                    'currentBattle': battleRef.id,
                    'ready': false
                })
            })

            function getArmor(slot) {
                if (playerData['equipment'][slot] != "") {
                    return playerRef.collection('inventory').doc(playerData['equipment'][slot]).get().then(itemSnap => {
                        var itemData = itemSnap.data();
                        var itemLvl = itemData['lvl']
                        var itemName = itemData['name']

                        return db.collection('equipment').doc(itemName).get().then(generalSnap => {
                            var generalData = generalSnap.data()
                            var generalArmor = generalData['armor']

                            equip[slot] = playerData['equipment'][slot]
                            armor += generalArmor * itemLvl * playerData['stats']['strength'];
                        })
                    })
                }
            }

            function getSkill(slot) {
                var skillName = playerData['equipment'][slot];
                return db.collection('skills').doc(skillName).get().then(skillSnap => {
                    var skillData = skillSnap.data();
                    skillData['name'] = skillName;
                    skills[slot] = skillData
                })
            }
        })
    }
    // MAKE ENEMIES after the players are made -----------------------------
    return Promise.all(playerPromises).then(() => {
        var promises = []
        Object.keys(enemiesDict).forEach(enemy => {
            for (var i = 0; i < enemiesDict[enemy]['count']; i++) {
                promises.push(getEnemy(enemy));
            }
        }); // ADD SOMETHING FOR MODIFIERS HERE

        // Sets order of attack
        return Promise.all(promises).then(() => {
            var order = Object.keys(orderDict).map(function (key) {
                return [key, orderDict[key]];
            });

            order.sort(function (first, second) {
                return second[1] - first[1];
            });

            var arr = []
            order.forEach(unitArr => {
                arr.push(unitArr[0]);
            })
            return battleRef.set({
                'order': arr,
                'log': {},
                'turn': 1,
                'adventure': data['adventure']
            })
        })

        function getEnemy(enemy) {
            var lvl = level;
            return db.collection('units').doc(enemy).get().then((snap) => {
                var unitData = snap.data();
                var skills = {}
                var skillPromises = []
                for (var i = 1; i < 5; i++) {
                    var skillName = unitData['possibleSkills'][0] //Math.floor(Math.random() * 4)];
                    skillPromises.push(enemySkill(skillName, i))
                    //skills.push(skillName);
                }

                function enemySkill(skillName, index) {
                    return db.collection('skills').doc(skillName).get().then(skillSnap => {
                        var skillData = skillSnap.data();
                        skillData['name'] = skillName;
                        skills['skill' + index] = skillData
                    })
                }

                return Promise.all(skillPromises).then(() => {
                    unitData['skills'] = skills
                    unitData['name'] = enemy
                    unitData['lvl'] = lvl;
                    unitData['effects'] = {};
                    unitData['effects']['dot'] = [];
                    unitData['effects']['status'] = [];

                    stats.forEach(stat => {
                        unitData['stats'][stat] = unitData['stats'][stat] * lvl;
                    })

                    unitData['hp'] = unitData['stats']['constitution'] * constitutionMult;
                    unitData['maxHP'] = unitData['hp']
                    unitData['armor'] = unitData['armor'] * unitData['stats']['strength'];
                    unitData['maxArmor'] = unitData['armor'];


                    return battleRef.collection('enemies').add(
                        unitData
                    ).then(res => {
                        orderDict[res.id] = unitData['stats']['dexterity']
                    });
                })
            });
        }
    });
});

// for each enemy in battleID, pick random skill, use it against random ally (Add to queue with caster, skill, target)
exports.enemySkill = functions.firestore.document('battles/{battleID}').onWrite((change, context) => {
    const battleID = context.params.battleID;
    if (change.before.get('turn') == change.after.get('turn')) {
        return;
    }


    return db.collection('battles').doc(battleID).collection('enemies').get().then(enemiesSnap => {
        var promises = []
        enemiesSnap.docs.forEach(doc => {
            promises.push(addQueue(doc))
        })

        return Promise.all(promises).then(() => {
            return;
        })

        function addQueue(doc) {
            var enemyData = doc.data()
            var skillNum = Math.ceil(Math.random() * 4)
            var chosenSkill = enemyData['skills']['skill' + skillNum]['name']
            var targetCount = enemyData['skills']['skill' + skillNum]['targets']
            var targets = []


            return db.collection('battles').doc(battleID).collection('allies').get().then(alliesSnap => {
                for (var i = 0; i < targetCount; i++) {
                    targets.push(alliesSnap.docs[Math.floor(Math.random() * alliesSnap.docs.length)].id)
                }

                return db.collection('battles').doc(battleID).collection('queue').doc(doc.id).set({
                    'skill': chosenSkill,
                    'targets': targets
                })
            })
        }
    })
})

// Get action, add to queue map
// Look at skill, find damage
// Find damage: Multiply damage by unit damage + stat bonus
// Apply damage to unit
exports.executeSkills = functions.firestore.document('battles/{battleID}/queue/{unitID}').onCreate((snap, context) => {
    const battleID = context.params.battleID;
    var order = [];
    var queue = {};
    var alliesID = [];
    var enemiesID = [];
    var unitNames = {};
    var log = {};
    var turn = 0;

    // Add queue to queue map
    return db.collection('battles').doc(battleID).collection('queue').get().then(queueSnap => {
        queueSnap.forEach(docSnap => {
            var data = docSnap.data();
            var skillName = data['skill'];
            var targets = data['targets'];

            queue[docSnap.id] = [skillName, targets]
        });
        // Get order  
    }).then(() => {
        return db.collection('battles').doc(battleID).get().then(battleSnap => {
            var battleData = battleSnap.data();
            order = battleData['order'];
            turn = battleData['turn'];
        })
        // Add id of allies to alliesID
    }).then(() => {
        return db.collection('battles').doc(battleID).collection('allies').get().then(snap => {
            snap.forEach(docSnap => {
                alliesID.push(docSnap.id);
            })
        })
        // Add id of enemies to enemiesID
    }).then(() => {
        return db.collection('battles').doc(battleID).collection('enemies').get().then(snap => {
            snap.forEach(docSnap => {
                enemiesID.push(docSnap.id);
            })
        })
    }).then(() => {
        // Execute skills through recursion (magic)

        if (Object.keys(queue).length != order.length) {
            return null;
        }

        return execute(0)
            .then(() => {
                return db.collection('battles').doc(battleID).collection('queue').get().then(queueSnap => {
                    queueSnap.docs.forEach(docSnap => {
                        db.collection('battles').doc(battleID).collection('queue').doc(docSnap.id).delete();
                    })
                })
            }).then(() => {
                return db.collection('battles').doc(battleID).update({
                    'log': log,
                    'turn': (turn + 1)
                })
            })
    })

    function execute(orderIndex) {
        var casterID = order[orderIndex];
        var casterEffects;
        var casterData;

        var casterSide = '';
        casterSide = (alliesID.includes(casterID) ? 'allies' : 'enemies');

        log[casterID] = [];

        // Apply dot
        return db.collection('battles').doc(battleID).collection(casterSide).doc(casterID).get().then(casterSnap => {
            casterData = casterSnap.data();
            casterEffects = casterData['effects'];
            var casterDotEffects = casterData['effects']['dot'];
            var dotCasters = []
            if (casterDotEffects.length != 0) {
                var finDotDamage = 0;
                var armor = casterData['armor'];
                var hp = casterData['hp'];

                for (var i = 0; i < casterDotEffects.length; i++) {
                    if (!dotCasters.includes(casterDotEffects[i]['caster'])) {
                        dotCasters.push(casterDotEffects[i]['caster']);
                    }

                    var dotDamage = casterDotEffects[i]['damage'];
                    if (casterDotEffects[i]['type'] != "") {
                        var resistance = casterData['resistances'][casterDotEffects[i]['type']] / 100;
                        dotDamage -= resistance * dotDamage;
                    }

                    finDotDamage += dotDamage;
                    casterDotEffects[i]['duration'] -= 1;
                }

                for (var i = casterDotEffects.length - 1; i >= 0; i--) {
                    if (casterDotEffects[i]['duration'] == 0) {
                        casterDotEffects.splice(i, 1);
                    }
                }

                if (finDotDamage > 0) {
                    armor -= finDotDamage
                    if (armor < 0) {
                        hp -= Math.abs(armor);
                        armor = 0
                    }
                } else {
                    hp -= finDotDamage
                    if (hp > casterData['maxHP']) {
                        hp = casterData['maxHP'];
                    }
                }

                log[casterID].push('- ' + casterData['name'] + ' took ' + shortInt(finDotDamage) + ' from DoT by ' + dotCasters.join(', '));

                casterEffects['dot'] = casterDotEffects;

                return db.collection('battles').doc(battleID).collection(casterSide).doc(casterID).update({
                    'hp': hp,
                    'armor': armor,
                    'effects': casterEffects
                })
            } else {
                return null;
            }
        }).then(() => {
            var skillName = queue[casterID][0];
            var targets = queue[casterID][1];
            var finDamage = 0;
            var crit = false;
            var skillType = "";
            var skillEffects = {};
            // Get skill damage
            return db.collection('skills').doc(skillName).get().then(skillSnap => {
                var skillData = skillSnap.data();
                var skillDamage = skillData['damage'];
                var skillStat = skillData['stat'];
                skillType = skillData['type'];
                skillEffects = skillData['effects'];

                // Get unit damage Find damage: Multiply damage by unit damage + stat bonus
                unitNames[casterID] = casterData['name'];
                var casterDamage = casterData['damage'];
                var casterCritChance = casterData['critChance'];
                if (Math.random() * 100 < casterCritChance) {
                    crit = true;
                    casterDamage *= (casterData['critDamage'] / 100);
                }

                var statBonus = casterData['stats'][skillStat];
                var statBonusDamage = statBonus * skillDamage;

                finDamage = (skillDamage * casterDamage) + statBonusDamage;

                // Apply damage to unit
            }).then(() => {
                var targetPromises = []
                targets.forEach(targetID => {
                    targetPromises.push(castTarget(targetID));
                })

                return Promise.all(targetPromises).then(() => {
                    for (var i = 0; i < targets.length; i++) {
                        targets[i] = unitNames[targets[i]];
                    }

                    var critStr = ''
                    if (crit) {
                        critStr = ' critical';
                    }

                    log[casterID].push('- ' + unitNames[casterID] + ' cast ' + skillName + ' on ' + targets.join(', ') + ' for ' + shortInt(finDamage) + critStr + ' damage.');
                });

                function castTarget(targetID) {
                    var side = '';
                    (alliesID.includes(targetID)) ? side = 'allies': side = 'enemies'

                    return db.collection('battles').doc(battleID).collection(side).doc(targetID).get().then(targetSnap => {
                        var targetData = targetSnap.data();
                        unitNames[targetID] = targetData['name'];
                        var hp = targetData['hp']
                        var armor = targetData['armor']
                        var targetEffects = targetData['effects'];
                        var targetStats = targetData['stats'];
                        var targetResistances = targetData['resistances'];

                        if (skillType != "") {
                            var resistance = targetData['resistances'][skillType] / 100;
                            finDamage -= resistance * finDamage;
                        }

                        if (finDamage > 0) {
                            armor -= finDamage
                            if (armor < 0) {
                                hp -= Math.abs(armor);
                                armor = 0
                            }
                        } else {
                            hp -= finDamage
                            if (hp > targetData['maxHP']) {
                                hp = targetData['maxHP'];
                            }
                        }

                        if (skillEffects != null && Object.keys(skillEffects) != 0) { // Has effects
                            if (Object.keys(skillEffects).includes('dot')) {
                                var dots = skillEffects['dot'];
                                dots.forEach(dot => {
                                    dot['damage'] = finDamage * dot['damage'] / 100;
                                    dot['caster'] = unitNames[casterID];
                                    targetEffects['dot'].push(dot);
                                })
                            }

                            // Casting stat change
                            if (Object.keys(skillEffects).includes('status')) {
                                var statuses = skillEffects['status'];
                                statuses.forEach(status => {
                                    if (Object.keys(status).includes('stats')) {
                                        Object.keys(status['stats']).forEach(statToChange => {
                                            var changeAmount = status['stats'][statToChange];
                                            targetStats[statToChange] += changeAmount;
                                        })
                                    }

                                    if (Object.keys(status).includes('resistances')) {
                                        Object.keys(status['resistances']).forEach(resToChange => {
                                            var changeAmount = status['resistances'][resToChange];
                                            targetResistances[resToChange] += changeAmount;
                                        })
                                    }

                                    status['casterID'] = casterID;
                                    targetEffects['status'].push(status);
                                })
                            }
                        }


                        return db.collection('battles').doc(battleID).collection(side).doc(targetID).update({
                            'hp': hp,
                            'armor': armor,
                            'effects': targetEffects,
                            'stats': targetStats,
                            'resistances': targetResistances
                        })
                    })
                }
                // Reduce duration by 1, remove old, add new caster effects
            }).then(() => {
                // decrement status effects by 1
                if (casterEffects['status'].length != 0) {
                    var statuses = casterEffects['status'];
                    statuses.forEach(status => {
                        status['duration']--;
                    })
                }

                // remove old
                if (casterEffects['status'].length != 0) {
                    var statusPromises = [];
                    var casterResistances = casterData['resistances'];
                    var casterStats = casterData['stats'];

                    for (var i = casterEffects['status'].length - 1; i >= 0; i--) {
                        var status = casterEffects['status'][i];
                        if (status['duration'] == 0) {
                            statusPromises.push(removeStatus(i))
                        }
                    }

                    function removeStatus(i) {
                        var status = casterEffects['status'][i];

                        Object.keys(status['resistances']).forEach(resistance => {
                            casterResistances[resistance] -= status['resistances'][resistance];
                        })

                        Object.keys(status['stats']).forEach(stat => {
                            casterStats[stat] -= status['stats'][stat];
                        })

                        casterEffects['status'].splice(i, 1);
                    }



                    Promise.all(statusPromises).then(() => {
                        return db.collection('battles').doc(battleID).collection(casterSide).doc(casterID).update({
                            'effects': casterEffects,
                            'resistances': casterResistances,
                            'stats': casterStats
                        })
                    })
                }
            })
        }).then(() => {
            if (order.length - 1 > orderIndex) {
                return execute(orderIndex + 1);
            }
        })

        function shortInt(num) {
            var str = '';
            if (num > 1000000) {
                num /= 100000;
                str = (Math.round(num) / 10) + 'M';
            } else if (num > 1000) {
                num /= 100;
                str = (Math.round(num) / 10) + 'K';
            } else {
                str = Math.round(num);
            }

            return str;
        }
    }
})

exports.newPlayer = functions.firestore.document('players/{uid}').onCreate((snap, context) => {
    const uid = context.params.uid;
    var snapData = snap.data();
    var pData = snapData['new'];
    var chosenClass = pData['class'];
    var startingItems = [];
    var startingSkills = [];
    var equipment = {
        'head': '',
        'torso': '',
        'hands': '',
        'legs': '',
        'feet': '',
        'skill1': '',
        'skill2': '',
        'skill3': '',
        'skill4': '',
        'weapon': ''
    }

    if (chosenClass == "rogue") {
        startingItems = ['Rusty Dagger', 'Worn Boots', 'Worn Hat', 'Worn Pants', 'Worn Gloves', 'Worn Tunic'];
        startingSkills = ['Stab'];
    } else if (chosenClass == "knight") {
        startingItems = ['Rusty Dagger', 'Worn Boots', 'Worn Hat', 'Worn Pants', 'Worn Gloves', 'Worn Tunic'];
        startingSkills = ['Stab'];
    } else if (chosenClass == "wizard") {
        startingItems = ['Rusty Dagger', 'Worn Boots', 'Worn Hat', 'Worn Pants', 'Worn Gloves', 'Worn Tunic'];
        startingSkills = ['Stab'];
    }

    var promises = [];
    startingItems.forEach(item => {
        promises.push(addItem(item));
    })

    function addItem(name) {
        return db.collection('players').doc(uid).collection('inventory').add({
            'name': name,
            'lvl': 1,
            'properties': {}
        })
    }

    return Promise.all(promises).then(() => {
        return db.collection('players').doc(uid).set({
            'gold': 100,
            'equipment': equipment,
            'stats': pData['stats'],
            'knownSkills': startingSkills,
            'name': pData['name'],
            'friends': [],
            'party': [uid],
            'sendInvite': "",
            'acceptInvite': "",
            'partyLeader': uid
        })
    });
});

exports.commands = functions.firestore.document('players/{uid}').onUpdate((change, context) => {
    const uid = context.params.uid;
    var aftData = change.after.data();

    // Sending an invite
    if (aftData['sendInvite'] != "") {
        var recUid = aftData['sendInvite'];
        return db.collection('players').doc(recUid).get().then(rec => {
            var recData = rec.data();
            var invites = recData['invites'];

            invites[uid] = admin.firestore.Timestamp.now();

            return db.collection('players').doc(recUid).update({
                'invites': invites
            }).then(() => {
                return db.collection('players').doc(uid).update({
                    'sendInvite': ""
                })
            })
        })
    }

    // Accepting an invite

    var invites = aftData['invites'];
    var inviter = aftData['acceptInvite']
    if ((inviter != "" && Object.keys(invites).includes(inviter)) || inviter == 'leave') {
        var currParty = aftData['party'];

        // Remove player from other player's parties
        var removePromises = [];
        var newLeader = null;

        // If the party leader is the one leaving, choose a new leader
        if (currParty[uid] == true) {
            for (var j = 0; j < Object.keys(currParty).length; j++) {
                if (Object.keys(currParty)[j] != uid) {
                    newLeader = Object.keys(currParty)[j];
                }
            }
        }
        for (var i = 0; i < Object.keys(currParty).length; i++) {
            if (Object.keys(currParty)[i] != uid) {

                removePromises.push(removeFromParty(Object.keys(currParty)[i], newLeader));
            }
        }


        return Promise.all(removePromises).then(() => {
            // Remove players from your party
            var leader = (inviter == 'leave' ? true : false);
            var tempParty = {};
            tempParty[uid] = leader;

            var inviterInvites = aftData['invites'];
            delete inviterInvites[inviter];
            return db.collection('players').doc(uid).update({
                'party': tempParty,
                'acceptInvite': "",
                'invites': inviterInvites
            });
        }).then(() => {
            if (inviter != 'leave') {
                // Add to new party. Look at inviter's party, add uid to all in inviter's party, add inviter's party to your party
                // ADD CATCH IF INVITER IS NOT VALID UID
                return db.collection('players').doc(inviter).get().then(snap => {
                    var data = snap.data();
                    var party = data['party'];

                    var addPromises = [];
                    Object.keys(party).forEach(member => {
                        addPromises.push(addToParty(member));
                    })

                    return Promise.all(addPromises).then(() => {
                        party[uid] = false;
                        return db.collection('players').doc(uid).update({
                            'party': party
                        });
                    })
                })
            } else {
                return null;
            }
        })
    }

    function removeFromParty(pUid, newLeader) {
        return db.collection('players').doc(pUid).get().then(snap => {
            var pData = snap.data();
            var pParty = pData['party'];

            if (newLeader != null) {
                pParty[newLeader] = true;
            }

            if (Object.keys(pParty).includes(uid)) {
                delete pParty[uid];
            }

            return db.collection('players').doc(pUid).update({
                'party': pParty
            })
        })
    }

    function addToParty(pUid) {
        return db.collection('players').doc(pUid).get().then(snap => {
            var pData = snap.data();
            var pParty = pData['party'];

            pParty[uid] = false;

            return db.collection('players').doc(pUid).update({
                'party': pParty
            })
        })
    }


    return null;
});