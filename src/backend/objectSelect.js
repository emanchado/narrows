/**
 * Returns a "filtered" object that only contains (at most) the
 * properties listed in the array `props`.
 */
export default function objectSelect(obj, props) {
    const final = {};

    props.forEach(p => {
        if (p in obj) {
            final[p] = obj[p];
        }
    });

    return final;
}
